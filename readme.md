# Projeto de Modelagem Data Vault com Apache Spark e Delta Lake

![Data Vault](https://img.shields.io/badge/Data%20Vault-2.0-blue)
![Apache Spark](https://img.shields.io/badge/Apache%20Spark-3.4.1-orange)
![Delta Lake](https://img.shields.io/badge/Delta%20Lake-2.4.0-green)
![Python](https://img.shields.io/badge/Python-3.10%2B-yellow)

Este projeto demonstra a implementação prática de uma arquitetura Data Vault utilizando Apache Spark, Delta Lake e Minio como armazenamento de objetos. A modelagem é aplicada ao conjunto de dados público brasileiro de E-Commerce da Olist.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Conceitos do Data Vault](#conceitos-do-data-vault)
- [Tecnologias Utilizadas](#tecnologias-utilizadas)
- [Arquitetura do Projeto](#arquitetura-do-projeto)
- [Pré-requisitos](#pré-requisitos)
- [Instalação e Execução](#instalação-e-execução)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Conjunto de Dados](#conjunto-de-dados)
- [Solução de Problemas](#solução-de-problemas)
- [Referências](#referências)

## 🌟 Visão Geral

A arquitetura Data Vault é uma metodologia de modelagem de dados projetada para:

- Fornecer um histórico auditável e completo de todos os dados
- Ser altamente adaptável a mudanças de requisitos de negócios
- Separar as regras de negócio dos dados brutos
- Escalar de forma eficiente para grandes volumes de dados

Este projeto implementa um ambiente completo para Data Vault usando:

- **Apache Spark**: Para processamento distribuído de dados
- **Delta Lake**: Para garantir transações ACID e viagem no tempo
- **Minio**: Como armazenamento de objetos compatível com S3
- **Jupyter Notebook**: Para desenvolvimento interativo e exploração de dados

## 🧩 Conceitos do Data Vault

O Data Vault consiste em três tipos principais de componentes:

1. **Hubs**: Armazenam as chaves de negócio e identificadores únicos das entidades
   - Representam o "o quê" dos dados
   - Contêm um hash de chave de negócio (Hub Key) e a chave de negócio original

2. **Links**: Armazenam as relações entre os hubs
   - Representam o "como" os dados estão conectados
   - Contêm referências (chaves estrangeiras) para os hubs que relacionam

3. **Satellites**: Armazenam os atributos descritivos dos hubs e links
   - Representam o "contexto" e os detalhes das entidades
   - São datados e historicizados para rastrear mudanças ao longo do tempo

![Estrutura Data Vault](https://github.com/your-username/data-vault-spark-delta/raw/main/docs/data_vault_structure.png)

## 🔧 Tecnologias Utilizadas

- **Python 3.10+**
- **Apache Spark 3.4.1**: Framework de processamento distribuído
- **Delta Lake 2.4.0**: Camada de armazenamento transacional para data lakes
- **Minio**: Armazenamento de objetos compatível com S3
- **Docker & Docker Compose**: Para containerização e orquestração
- **Jupyter Notebook**: Ambiente interativo para exploração e modelagem
- **Poetry**: Gerenciamento de dependências Python

## 🏗️ Arquitetura do Projeto

A arquitetura implementada neste projeto inclui:

- **Cluster Spark**: Um master e dois workers para processamento distribuído
- **Minio**: Para armazenar os dados brutos, simulando um data lake
- **Jupyter Notebook**: Para desenvolvimento interativo e execução das transformações
- **Volume de dados**: Mapeado entre o host e os containers para persistência

Os dados fluem através dos seguintes estágios:

1. Ingestão dos dados brutos no Minio
2. Leitura e processamento com Spark
3. Modelagem Data Vault (Hubs, Links, Satellites)
4. Armazenamento como tabelas Delta Lake
5. Consultas e análises sobre o modelo Data Vault

## 📋 Pré-requisitos

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/)
- Git

## 🚀 Instalação e Execução

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/data-vault-spark-delta.git
cd data-vault-spark-delta
```

### 2. Prepare os dados e configure o ambiente

Execute o script de preparação para baixar o conjunto de dados e configurar o Minio:

```bash
chmod +x scripts/download_dataset.sh
./scripts/download_dataset.sh

# Configure o Minio (caso necessário)
chmod +x scripts/fix_minio_setup.sh
./scripts/fix_minio_setup.sh
```

### 3. Inicie os serviços com Docker Compose

```bash
docker-compose up -d
```

### 4. Acesse o Jupyter Notebook

Abra seu navegador e acesse:

```
http://localhost:8888
```

Não é necessário senha ou token para acesso.

### 5. Acesse a interface do Minio (opcional)

Para explorar os dados armazenados no Minio:

```
http://localhost:9001
```

Credenciais padrão: 
- Usuário: `minioadmin`
- Senha: `minioadmin`

## 📁 Estrutura do Projeto

```
.
├── docker-compose.yml           # Configuração dos serviços Docker
├── jupyter/                     # Configuração do Jupyter
│   └── Dockerfile               # Dockerfile personalizado para o Jupyter
├── notebooks/                   # Notebooks Jupyter
│   └── data_vault_modeling.ipynb  # Implementação do Data Vault
├── pyproject.toml               # Configuração do Poetry e dependências
├── README.md                    # Este arquivo
├── scripts/                     # Scripts utilitários
│   ├── download_dataset.sh      # Script para download dos dados
│   └── fix_minio_setup.sh       # Script para configuração do Minio
└── data/                        # Diretório para armazenar dados (ignorado pelo Git)
    ├── raw/                     # Dados brutos em CSV
    ├── minio_data/              # Dados do Minio
    └── delta/                   # Tabelas Delta Lake geradas
```

## 📊 Conjunto de Dados

Este projeto utiliza o conjunto de dados público brasileiro de E-Commerce da Olist, que contém informações sobre pedidos, produtos, clientes e vendedores. Este dataset inclui:

- **Pedidos**: Status, datas de compra, aprovação e entrega
- **Clientes**: Localização geográfica (cidade, estado)
- **Produtos**: Categorias, dimensões, pesos
- **Vendedores**: Localização geográfica
- **Itens de Pedido**: Preços, fretes, datas de envio

Este cenário é ideal para demonstração de modelagem Data Vault, pois contém múltiplas entidades com relacionamentos diversos e atributos contextuais.

## 🔍 Solução de Problemas

### Problemas de conexão com o Minio

Se encontrar problemas ao tentar ler os dados do Minio, execute:

```bash
./scripts/fix_minio_setup.sh
```

Este script configura o bucket do Minio, carrega os arquivos e verifica se os JARs necessários para o S3A estão disponíveis.

### Erros do S3A FileSystem no Spark

Se ocorrerem erros como `ClassNotFoundException: Class org.apache.hadoop.fs.s3a.S3AFileSystem not found`, adicione o seguinte código ao seu notebook:

```python
# Cole o conteúdo do arquivo minio_integration.py em uma célula do notebook
```

### Alternativa: Leitura Local dos Dados

Se a integração com o Minio continuar apresentando problemas, você pode optar por ler os dados diretamente do sistema de arquivos local. O código em `minio_integration.py` já inclui um fallback automático para isso.

## 📚 Referências

- [Data Vault Alliance](https://datavaultalliance.com/)
- [Delta Lake Documentation](https://docs.delta.io/)
- [Apache Spark Documentation](https://spark.apache.org/docs/)
- [Minio Documentation](https://docs.min.io/)
- [Dataset Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- [Data Vault 2.0 Methodology](https://www.data-vault.co.uk/data-vault-2-0-methodology/)

---


- Desenvolvido com ❤️ de Airton Lira Junior para comunidade.
- MeuLinkedln: https://www.linkedin.com/in/airton-lira-junior-6b81a661/