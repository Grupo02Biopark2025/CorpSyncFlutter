# 📱 CorpSync – MDM App Flutter + Node.js + PostgreSQL

Este projeto é um sistema de gerenciamento de dispositivos móveis (MDM) com autenticação de usuários. O app é desenvolvido com **Flutter**, se comunica com um backend **Node.js + Prisma**, e utiliza **PostgreSQL** como banco de dados.

---

## ✅ Requisitos

### 📦 Backend:
- Node.js (v18+)
- PostgreSQL instalado e rodando
- Prisma ORM

### 📲 Frontend (Flutter):
- Flutter SDK instalado
- Celular ou emululador configurado
- Conexão com o backend via IP local (para testes em dispositivos reais)

---

## 🚀 Como rodar o projeto

### 🔧 1. Clonar o repositório

```bash
git clone <repo_url>
cd corp_syncmdm
```

---

### ⚙️ 2. Backend – Node.js

#### a) Instalar dependências

```bash
cd nodeProjetoIntegrador
npm install
```

#### b) Criar banco PostgreSQL (ex: no pgAdmin)

Nome: `syncmdm`

#### c) Arquivo `.env` na raiz do backend:

```env
PORT=4040

DB_USER=postgres
DB_PASSWORD=admin
DB_HOST=localhost
DB_PORT=5432
DB_NAME=syncmdm

DATABASE_URL="postgresql://postgres:admin@localhost:5432/syncmdm?schema=public"
SECRET_KEY=admin
```

#### d) Rodar Prisma

```bash
npx prisma generate
npx prisma migrate dev --name init
```

#### e) Inserir usuário de teste

```sql
INSERT INTO "User" (name, email, password)
VALUES (
  'Usuario',
  'user@mdm.com',
  '$2b$10$LSJAYKHKdd5m6FEC1DzCA.5DyL291cgHMa8YWhWgk6a9xb97lYt.i'
);
```

#### f) Rodar servidor

```bash
npm start
```

---

### 📱 3. Frontend – Flutter

#### a) Atualize a URL do login em `tela_login.dart`:

```dart
final url = Uri.parse('http://<IP_LOCAL>:4040/api/auth/login');
```

> Exemplo: `http://192.168.0.105:4040/api/auth/login`

#### b) Instalar dependências

```bash
flutter pub get
```

#### c) Executar o app

```bash
flutter run
```

---

## 🔐 Credenciais de teste

```
Email: user@mdm.com
Senha: 123456
```

---

## 🧪 Funcionalidades até o momento

- Login integrado com backend
- Token JWT salvo com SharedPreferences
- Logout funcional
- Redirecionamento automático
- Provider com usuário logado
- Drawer com opções de navegação

---


