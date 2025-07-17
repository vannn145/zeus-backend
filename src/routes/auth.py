"""
Rotas de autenticação do Sistema de Gestão Logística (Versão Corrigida)
"""
from datetime import datetime, timedelta
from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import (
    create_access_token, create_refresh_token, jwt_required,
    get_jwt_identity, get_jwt
)
from werkzeug.security import check_password_hash, generate_password_hash
from sqlalchemy import or_
import uuid

# Importar db da aplicação principal
from src.main_fixed import db

# Modelo User simplificado
class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = db.Column(db.String(50), unique=True, nullable=False)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    first_name = db.Column(db.String(100), nullable=False)
    last_name = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(20))
    is_active = db.Column(db.Boolean, default=True)
    last_login = db.Column(db.DateTime)
    password_changed_at = db.Column(db.DateTime, default=datetime.utcnow)
    failed_login_attempts = db.Column(db.Integer, default=0)
    locked_until = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
        self.password_changed_at = datetime.utcnow()
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def get_roles(self):
        return []
    
    def has_permission(self, resource, action):
        return True
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"
    
    def to_dict(self):
        return {
            'id': str(self.id),
            'username': self.username,
            'email': self.email,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'full_name': self.full_name,
            'phone': self.phone,
            'is_active': self.is_active,
            'last_login': self.last_login.isoformat() if self.last_login else None,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/login', methods=['POST'])
def login():
    """Endpoint de login do usuário"""
    try:
        data = request.get_json()
        
        # Validar campos obrigatórios
        if not data or 'username' not in data or 'password' not in data:
            return jsonify({
                'error': 'Dados inválidos',
                'message': 'Username e password são obrigatórios'
            }), 400
        
        username = data['username'].strip().lower()
        password = data['password']
        
        # Buscar usuário por username ou email
        user = User.query.filter(
            or_(
                User.username == username,
                User.email == username
            )
        ).first()
        
        if not user:
            return jsonify({
                'error': 'Credenciais inválidas',
                'message': 'Usuário ou senha incorretos'
            }), 401
        
        # Verificar se usuário está ativo
        if not user.is_active:
            return jsonify({
                'error': 'Usuário inativo',
                'message': 'Sua conta está desativada. Entre em contato com o administrador.'
            }), 401
        
        # Verificar se usuário está bloqueado
        if user.locked_until and user.locked_until > datetime.utcnow():
            return jsonify({
                'error': 'Usuário bloqueado',
                'message': f'Conta bloqueada até {user.locked_until.strftime("%d/%m/%Y %H:%M")}',
                'locked_until': user.locked_until.isoformat()
            }), 401
        
        # Verificar senha
        if not user.check_password(password):
            # Incrementar tentativas de login falhadas
            user.failed_login_attempts += 1
            
            # Bloquear usuário após 5 tentativas
            if user.failed_login_attempts >= 5:
                user.locked_until = datetime.utcnow() + timedelta(minutes=30)
                db.session.commit()
                
                return jsonify({
                    'error': 'Muitas tentativas',
                    'message': 'Conta bloqueada por 30 minutos devido a muitas tentativas de login falhadas'
                }), 401
            
            db.session.commit()
            
            return jsonify({
                'error': 'Credenciais inválidas',
                'message': 'Usuário ou senha incorretos',
                'attempts_remaining': 5 - user.failed_login_attempts
            }), 401
        
        # Login bem-sucedido - resetar tentativas e atualizar último login
        user.failed_login_attempts = 0
        user.locked_until = None
        user.last_login = datetime.utcnow()
        db.session.commit()
        
        # Criar tokens JWT
        access_token = create_access_token(
            identity=str(user.id),
            additional_claims={
                'username': user.username,
                'email': user.email,
                'full_name': user.full_name,
                'roles': [role.name for role in user.get_roles()]
            }
        )
        
        refresh_token = create_refresh_token(identity=str(user.id))
        
        return jsonify({
            'message': 'Login realizado com sucesso',
            'access_token': access_token,
            'refresh_token': refresh_token,
            'user': user.to_dict(),
            'roles': [role.to_dict() for role in user.get_roles()]
        }), 200
        
    except Exception as e:
        current_app.logger.error(f"Erro no login: {str(e)}")
        db.session.rollback()
        return jsonify({
            'error': 'Erro interno',
            'message': 'Erro interno do servidor'
        }), 500

@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """Obter informações do usuário atual"""
    try:
        current_user_id = get_jwt_identity()
        
        user = User.query.get(current_user_id)
        if not user:
            return jsonify({
                'error': 'Usuário não encontrado'
            }), 404
        
        return jsonify({
            'user': user.to_dict(),
            'roles': [role.to_dict() for role in user.get_roles()],
            'permissions': []
        }), 200
        
    except Exception as e:
        current_app.logger.error(f"Erro ao obter usuário atual: {str(e)}")
        return jsonify({
            'error': 'Erro interno',
            'message': 'Erro interno do servidor'
        }), 500

@auth_bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    """Endpoint de logout (invalidar token)"""
    return jsonify({
        'message': 'Logout realizado com sucesso'
    }), 200

