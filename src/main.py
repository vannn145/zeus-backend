"""
Sistema de Gestão Logística - API Backend (Versão Corrigida)
Aplicação Flask principal com configuração simplificada
"""
import os
import sys
import logging
from datetime import datetime

# Configuração do path
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from flask import Flask, send_from_directory, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS

# Configuração simplificada
class Config:
    SECRET_KEY = 'logistics-system-secret-key-2025'
    SQLALCHEMY_DATABASE_URI = 'sqlite:///logistics_dev.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = 'jwt-secret-key-logistics-2025'
    CORS_ORIGINS = ['*']

# Inicializar extensões
db = SQLAlchemy()
jwt = JWTManager()

def create_app():
    """Factory function para criar a aplicação Flask"""
    
    app = Flask(__name__, static_folder=os.path.join(os.path.dirname(__file__), 'static'))
    
    # Carregar configurações
    app.config.from_object(Config)
    
    # Inicializar extensões
    db.init_app(app)
    jwt.init_app(app)
    
    # Configurar CORS
    CORS(app, origins=app.config['CORS_ORIGINS'])
    
    # Registrar blueprints
    register_blueprints(app)
    
    # Configurar handlers de erro
    setup_error_handlers(app)
    
    # Criar tabelas do banco de dados
    with app.app_context():
        try:
            db.create_all()
            app.logger.info("Tabelas do banco de dados criadas com sucesso")
        except Exception as e:
            app.logger.error(f"Erro ao criar tabelas do banco: {str(e)}")
    
    return app

def register_blueprints(app):
    """Registrar apenas blueprints essenciais"""
    
    # Importar apenas blueprint de autenticação
    from src.routes.auth_fixed import auth_bp
    
    # Registrar apenas blueprint de auth
    app.register_blueprint(auth_bp, url_prefix='/api/auth')

def setup_error_handlers(app):
    """Configurar handlers de erro personalizados"""
    
    @app.errorhandler(400)
    def bad_request(error):
        return jsonify({
            'error': 'Bad Request',
            'message': 'Requisição inválida',
            'status_code': 400
        }), 400
    
    @app.errorhandler(401)
    def unauthorized(error):
        return jsonify({
            'error': 'Unauthorized',
            'message': 'Acesso não autorizado',
            'status_code': 401
        }), 401
    
    @app.errorhandler(403)
    def forbidden(error):
        return jsonify({
            'error': 'Forbidden',
            'message': 'Acesso negado',
            'status_code': 403
        }), 403
    
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({
            'error': 'Not Found',
            'message': 'Recurso não encontrado',
            'status_code': 404
        }), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        db.session.rollback()
        return jsonify({
            'error': 'Internal Server Error',
            'message': 'Erro interno do servidor',
            'status_code': 500
        }), 500

# Rota de health check
def setup_health_routes(app):
    """Configurar rotas de health check"""
    
    @app.route('/api/health')
    def health_check():
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat(),
            'version': '1.0.0',
            'service': 'Sistema de Gestão Logística API'
        })

# Criar aplicação
app = create_app()

# Configurar rotas adicionais
setup_health_routes(app)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)

