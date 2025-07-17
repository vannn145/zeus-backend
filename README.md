# 🚛 Sistema de Gestão Logística

Sistema completo de gestão logística desenvolvido com **React** + **Flask**, incluindo 6 módulos principais para controle de suprimentos, inventário, transporte, custos e analytics.

## 🚀 Início Rápido no VS Code

### 1. Abrir Projeto
```bash
# Extrair ZIP e abrir no VS Code
code .
```

### 2. Instalar Extensões Recomendadas
O VS Code sugerirá automaticamente as extensões necessárias. Clique em **"Install All"** quando aparecer a notificação.

### 3. Configurar Ambiente

#### Frontend (React)
```bash
# Terminal 1
cd logistics-frontend
npm install
npm run dev
```
🌐 Frontend: http://localhost:5173

#### Backend (Flask)
```bash
# Terminal 2
cd logistics_api
python -m venv venv

# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

pip install -r requirements.txt
python init_simple.py
python src/main.py
```
🔧 API: http://localhost:5000

### 4. Credenciais de Teste
- **Usuário:** admin
- **Senha:** admin123

## 📁 Estrutura do Projeto

```
📦 sistema-gestao-logistica/
├── 📁 .vscode/                    # Configurações VS Code
├── 📁 logistics-frontend/         # Frontend React
│   ├── 📁 src/
│   │   ├── 📁 components/         # Componentes React
│   │   ├── 📁 pages/              # Páginas da aplicação
│   │   ├── 📁 contexts/           # Context API
│   │   └── 📁 hooks/              # Custom hooks
│   ├── 📁 dist/                   # Build de produção
│   └── 📄 package.json
├── 📁 logistics_api/              # Backend Flask
│   ├── 📁 src/
│   │   ├── 📁 models/             # Modelos de dados
│   │   ├── 📁 routes/             # Rotas da API
│   │   └── 📁 utils/              # Utilitários
│   └── 📄 requirements.txt
├── 📄 *.md                        # Documentação
└── 📄 *.sql                       # Scripts de banco
```

## ⚡ Comandos Rápidos (VS Code)

Use `Ctrl+Shift+P` e digite:

- **"Tasks: Run Task"** → Executar tarefas pré-configuradas
- **"Python: Select Interpreter"** → Selecionar ambiente virtual
- **"Developer: Reload Window"** → Recarregar VS Code

### Tarefas Disponíveis:
- `Install Frontend Dependencies`
- `Start Frontend Dev Server`
- `Install Backend Dependencies`
- `Initialize Database`
- `Start Backend API`

## 🎯 Funcionalidades

### ✅ Implementadas
- 🔐 Sistema de autenticação JWT
- 📊 Dashboard interativo com gráficos
- 👥 Gestão de usuários
- 🎨 Interface responsiva moderna
- 🌙 Tema claro/escuro
- 📱 Design mobile-first

### 🚧 Módulos Estruturados
- 📦 Gestão de Suprimentos
- 🏪 Armazenagem e Inventário
- 🚚 Gestão de Transporte
- 💰 Custos Logísticos
- 💳 Financeiro Logístico
- 📈 Indicadores de Performance (KPIs)

## 🛠️ Tecnologias

### Frontend
- ⚛️ React 19 + Vite
- 🎨 Tailwind CSS + shadcn/ui
- 📊 Recharts (gráficos)
- 🧭 React Router
- 🔄 Context API

### Backend
- 🐍 Python 3.11 + Flask
- 🗄️ SQLAlchemy + SQLite/PostgreSQL
- 🔑 JWT Authentication
- 📝 RESTful API
- 🔒 CORS + Security

## 📚 Documentação

- **`README-INSTALACAO.md`** - Guia completo de instalação
- **`analise_requisitos_sistema_logistico.md`** - Análise detalhada (15k+ palavras)
- **`modelagem_dados_sistema_logistico.md`** - Modelagem do banco
- **`create_database_schema.sql`** - Scripts PostgreSQL

## 🚀 Deploy

### Frontend (Estático)
```bash
cd logistics-frontend
npm run build
# Copiar dist/ para servidor web
```

### Backend (Produção)
```bash
cd logistics_api
pip install gunicorn
gunicorn --bind 0.0.0.0:5000 src.main:app
```

## 🆘 Problemas Comuns

### Frontend não conecta com Backend
- Verificar se API está rodando na porta 5000
- Conferir `API_BASE_URL` em `src/contexts/AuthContext.jsx`

### Erro de dependências Python
```bash
cd logistics_api
pip install --upgrade pip
pip install -r requirements.txt
```

### Erro de dependências Node
```bash
cd logistics-frontend
rm -rf node_modules package-lock.json
npm install
```

## 📞 Suporte

- 📖 Consulte a documentação completa nos arquivos `.md`
- 🐛 Use o debugger integrado do VS Code (F5)
- 🔍 Verifique logs no terminal integrado

---

**Sistema de Gestão Logística v1.0**  
Desenvolvido com ❤️ usando React + Flask  
© 2025

hshshgssgsggs
