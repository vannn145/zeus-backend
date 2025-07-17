#!/usr/bin/env python3
"""
Script de teste simples para verificar o login
"""
import os
import sys
sys.path.insert(0, os.path.dirname(__file__))

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
import uuid
import requests
import json

# Configurar aplicação Flask simples
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///logistics_dev.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = 'test-secret-key'
app.config['JWT_SECRET_KEY'] = 'jwt-test-secret-key'

db = SQLAlchemy(app)
jwt = JWTManager(app)

# Definir modelo básico
class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = db.Column(db.String(50), unique=True, nullable=False)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    first_name = db.Column(db.String(100), nullable=False)
    last_name = db.Column(db.String(100), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    failed_login_attempts = db.Column(db.Integer, default=0)
    locked_until = db.Column(db.DateTime)
    last_login = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def get_roles(self):
        return []
    
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
            'is_active': self.is_active,
            'last_login': self.last_login.isoformat() if self.last_login else None,
            'created_at': self.created_at.isoformat()
        }

# Rota de login simples
@app.route('/api/auth/login', methods=['POST'])
def login():
    from flask import request, jsonify
    from flask_jwt_extended import create_access_token, create_refresh_token
    from sqlalchemy import or_
    
    try:
        data = request.get_json()
        
        if not data or 'username' not in data or 'password' not in data:
            return jsonify({
                'error': 'Dados inválidos',
                'message': 'Username e password são obrigatórios'
            }), 400
        
        username = data['username'].strip().lower()
        password = data['password']
        
        # Buscar usuário
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
        
        if not user.is_active:
            return jsonify({
                'error': 'Usuário inativo',
                'message': 'Sua conta está desativada'
            }), 401
        
        if not user.check_password(password):
            return jsonify({
                'error': 'Credenciais inválidas',
                'message': 'Usuário ou senha incorretos'
            }), 401
        
        # Login bem-sucedido
        user.last_login = datetime.utcnow()
        db.session.commit()
        
        # Criar tokens
        access_token = create_access_token(
            identity=str(user.id),
            additional_claims={
                'username': user.username,
                'email': user.email,
                'full_name': user.full_name
            }
        )
        
        refresh_token = create_refresh_token(identity=str(user.id))
        
        return jsonify({
            'message': 'Login realizado com sucesso',
            'access_token': access_token,
            'refresh_token': refresh_token,
            'user': user.to_dict()
        }), 200
        
    except Exception as e:
        print(f"Erro no login: {str(e)}")
        return jsonify({
            'error': 'Erro interno',
            'message': 'Erro interno do servidor'
        }), 500

@app.route('/api/health')
def health():
    from flask import jsonify
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'Test Login API'
    })

def main():
    print("🚀 Criando banco de teste...")
    
    with app.app_context():
        # Criar tabelas
        db.create_all()
        
        # Criar usuário admin se não existir
        admin_user = User.query.filter_by(username='admin').first()
        if not admin_user:
            admin_user = User(
                username='admin',
                email='admin@test.com',
                password_hash=generate_password_hash('admin123'),
                first_name='Admin',
                last_name='Test',
                is_active=True
            )
            db.session.add(admin_user)
            db.session.commit()
            print("✓ Usuário admin criado")
        else:
            print("✓ Usuário admin já existe")
    
    print("🚀 Iniciando servidor de teste...")
    app.run(host='0.0.0.0', port=5000, debug=False)

if __name__ == '__main__':
    main()

