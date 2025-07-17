# Sistema de Gestão Logística - Guia de Instalação

## 📋 Conteúdo do Pacote

Este arquivo ZIP contém o sistema completo de gestão logística desenvolvido com:

### Frontend (React)
- **Localização:** `logistics-frontend/`
- **Tecnologias:** React, Vite, Tailwind CSS, shadcn/ui
- **Build pronto:** `logistics-frontend/dist/` (arquivos estáticos)

### Backend (Flask/Python)
- **Localização:** `logistics_api/`
- **Tecnologias:** Flask, SQLAlchemy, JWT, PostgreSQL/SQLite
- **Banco:** SQLite já configurado para desenvolvimento

### Documentação
- **Análise de Requisitos:** `analise_requisitos_sistema_logistico.md`
- **Modelagem de Dados:** `modelagem_dados_sistema_logistico.md`
- **Scripts SQL:** `create_database_schema.sql`, `create_functions_triggers.sql`

## 🚀 Instalação Rápida

### Opção 1: Deploy apenas do Frontend (Recomendado para visualização)

1. **Extrair arquivos:**
   ```bash
   unzip sistema-gestao-logistica-clean.zip
   ```

2. **Servir arquivos estáticos:**
   ```bash
   # Copie o conteúdo de logistics-frontend/dist/ para seu servidor web
   cp -r logistics-frontend/dist/* /var/www/html/
   ```

3. **Configurar servidor web (Nginx/Apache):**
   ```nginx
   # Exemplo Nginx
   server {
       listen 80;
       server_name seu-dominio.com;
       root /var/www/html;
       index index.html;
       
       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```

### Opção 2: Instalação Completa (Frontend + Backend)

#### Backend (API Flask)

1. **Instalar Python e dependências:**
   ```bash
   cd logistics_api
   python3 -m venv venv
   source venv/bin/activate  # Linux/Mac
   # ou venv\Scripts\activate  # Windows
   pip install -r requirements.txt
   ```

2. **Inicializar banco de dados:**
   ```bash
   python init_simple.py
   ```

3. **Executar API:**
   ```bash
   python src/main.py
   ```
   - API rodará em: http://localhost:5000

#### Frontend (React)

1. **Instalar Node.js e dependências:**
   ```bash
   cd logistics-frontend
   npm install
   # ou
   pnpm install
   ```

2. **Para desenvolvimento:**
   ```bash
   npm run dev
   # ou
   pnpm run dev
   ```
   - Frontend rodará em: http://localhost:5173

3. **Para produção:**
   ```bash
   npm run build
   # Arquivos gerados em dist/
   ```

## 🔧 Configuração

### Variáveis de Ambiente (Backend)
```bash
# .env
DATABASE_URL=sqlite:///logistics_dev.db
SECRET_KEY=sua-chave-secreta-aqui
JWT_SECRET_KEY=sua-jwt-chave-aqui
```

### Configuração da API (Frontend)
Edite `logistics-frontend/src/contexts/AuthContext.jsx`:
```javascript
const API_BASE_URL = 'http://seu-servidor.com:5000/api'
```

## 👤 Credenciais de Teste

- **Usuário:** admin
- **Senha:** admin123

## 📁 Estrutura do Projeto

```
sistema-gestao-logistica/
├── logistics-frontend/          # Frontend React
│   ├── src/                    # Código fonte
│   ├── dist/                   # Build de produção
│   └── package.json            # Dependências
├── logistics_api/              # Backend Flask
│   ├── src/                    # Código fonte da API
│   ├── requirements.txt        # Dependências Python
│   └── init_simple.py          # Script de inicialização
├── analise_requisitos_sistema_logistico.md
├── modelagem_dados_sistema_logistico.md
├── create_database_schema.sql
└── create_functions_triggers.sql
```

## 🌐 Deploy em Produção

### Frontend
- Copie o conteúdo de `logistics-frontend/dist/` para seu servidor web
- Configure redirecionamento para `index.html` (SPA)

### Backend
- Use Gunicorn ou uWSGI para produção
- Configure PostgreSQL para banco de dados
- Use proxy reverso (Nginx) para a API

### Exemplo com Docker
```dockerfile
# Frontend
FROM nginx:alpine
COPY logistics-frontend/dist /usr/share/nginx/html

# Backend
FROM python:3.11
COPY logistics_api /app
WORKDIR /app
RUN pip install -r requirements.txt
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "src.main:app"]
```

## 🆘 Suporte

### Problemas Comuns

1. **Erro de CORS:** Configure CORS no backend para seu domínio
2. **Banco não inicializa:** Execute `python init_simple.py`
3. **Frontend não conecta:** Verifique `API_BASE_URL` no AuthContext

### Logs
- Backend: Logs aparecem no console
- Frontend: Use DevTools do navegador (F12)

## 📊 Funcionalidades Implementadas

✅ **Completas:**
- Sistema de autenticação JWT
- Dashboard interativo com gráficos
- Interface responsiva moderna
- Gestão de usuários
- Estrutura de banco de dados completa

🚧 **Em desenvolvimento:**
- Módulos de negócio específicos
- Integrações com APIs externas
- Relatórios avançados

## 📞 Contato

Para suporte técnico ou dúvidas sobre a implementação, consulte a documentação completa nos arquivos `.md` incluídos no pacote.

---
**Sistema de Gestão Logística v1.0**  
Desenvolvido com React + Flask  
© 2025

