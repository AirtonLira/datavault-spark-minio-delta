#!/bin/bash

# Script para baixar e preparar o conjunto de dados da Olist para modelagem Data Vault

# Criar diretórios necessários
mkdir -p data/raw
mkdir -p data/processed
mkdir -p data/delta

echo "Iniciando download do conjunto de dados da Olist..."

# Opção 1: Baixar diretamente sem usar o Kaggle CLI
echo "Baixando o conjunto de dados diretamente..."
# URL direta para o conjunto de dados da Olist já processado
wget -O data/raw/olist_dataset.zip https://github.com/olist/work-at-olist-data/raw/master/datasets/olist_public_dataset.zip || {
    echo "Não foi possível baixar usando wget. Tentando com curl..."
    curl -L -o data/raw/olist_dataset.zip https://github.com/olist/work-at-olist-data/raw/master/datasets/olist_public_dataset.zip || {
        echo "Não foi possível baixar o conjunto de dados diretamente."
        
        # Opção 2: Baixar usando o Kaggle CLI se a opção direta falhou
        echo "Tentando baixar usando o Kaggle CLI..."
        
        # Verificar se o Kaggle CLI está instalado, caso contrário instalar
        if ! command -v kaggle &> /dev/null
        then
            echo "Kaggle CLI não encontrado. Instalando..."
            pip install kaggle
            
            # Instruções para configurar a API do Kaggle se não estiver configurada
            if [ ! -f ~/.kaggle/kaggle.json ]; then
                echo "Por favor, configure sua API do Kaggle primeiro:"
                echo "1. Vá para https://www.kaggle.com/<seu_usuario>/account"
                echo "2. Clique em 'Create New API Token'"
                echo "3. Coloque o arquivo kaggle.json baixado em ~/.kaggle/"
                echo "4. Execute: chmod 600 ~/.kaggle/kaggle.json"
                echo "5. Execute este script novamente"
                
                # Opção 3: Usar dados de demonstração se tudo falhar
                echo "Criando dados de demonstração..."
                
                # Criar arquivo de demonstração para clientes
                echo "customer_id,customer_unique_id,customer_zip_code_prefix,customer_city,customer_state" > data/raw/olist_customers_dataset.csv
                echo "c1,cu1,12345,São Paulo,SP" >> data/raw/olist_customers_dataset.csv
                echo "c2,cu2,23456,Rio de Janeiro,RJ" >> data/raw/olist_customers_dataset.csv
                echo "c3,cu3,34567,Belo Horizonte,MG" >> data/raw/olist_customers_dataset.csv
                
                # Criar arquivo de demonstração para pedidos
                echo "order_id,customer_id,order_status,order_purchase_timestamp,order_approved_at,order_delivered_carrier_date,order_delivered_customer_date,order_estimated_delivery_date" > data/raw/olist_orders_dataset.csv
                echo "o1,c1,delivered,2018-01-01 10:00:00,2018-01-01 12:00:00,2018-01-02 10:00:00,2018-01-03 10:00:00,2018-01-10 10:00:00" >> data/raw/olist_orders_dataset.csv
                echo "o2,c1,shipped,2018-01-02 10:00:00,2018-01-02 12:00:00,2018-01-03 10:00:00,,2018-01-15 10:00:00" >> data/raw/olist_orders_dataset.csv
                echo "o3,c2,delivered,2018-01-03 10:00:00,2018-01-03 12:00:00,2018-01-04 10:00:00,2018-01-05 10:00:00,2018-01-12 10:00:00" >> data/raw/olist_orders_dataset.csv
                
                # Criar arquivo de demonstração para produtos
                echo "product_id,product_category_name,product_name_length,product_description_length,product_photos_qty,product_weight_g,product_length_cm,product_height_cm,product_width_cm" > data/raw/olist_products_dataset.csv
                echo "p1,electronics,10,100,3,1000,30,10,20" >> data/raw/olist_products_dataset.csv
                echo "p2,furniture,15,150,5,5000,100,50,40" >> data/raw/olist_products_dataset.csv
                echo "p3,household,12,120,2,500,20,15,10" >> data/raw/olist_products_dataset.csv
                
                # Criar arquivo de demonstração para vendedores
                echo "seller_id,seller_zip_code_prefix,seller_city,seller_state" > data/raw/olist_sellers_dataset.csv
                echo "s1,12345,São Paulo,SP" >> data/raw/olist_sellers_dataset.csv
                echo "s2,23456,Rio de Janeiro,RJ" >> data/raw/olist_sellers_dataset.csv
                echo "s3,34567,Belo Horizonte,MG" >> data/raw/olist_sellers_dataset.csv
                
                # Criar arquivo de demonstração para itens de pedido
                echo "order_id,order_item_id,product_id,seller_id,shipping_limit_date,price,freight_value" > data/raw/olist_order_items_dataset.csv
                echo "o1,1,p1,s1,2018-01-05 10:00:00,100.0,10.0" >> data/raw/olist_order_items_dataset.csv
                echo "o1,2,p2,s2,2018-01-05 10:00:00,200.0,20.0" >> data/raw/olist_order_items_dataset.csv
                echo "o2,1,p3,s3,2018-01-06 10:00:00,50.0,5.0" >> data/raw/olist_order_items_dataset.csv
                echo "o3,1,p1,s1,2018-01-07 10:00:00,100.0,10.0" >> data/raw/olist_order_items_dataset.csv
                
                echo "Dados de demonstração criados com sucesso!"
                echo "Os arquivos estão disponíveis em data/raw/"
                
                # Preparar arquivos para Minio
                mkdir -p data/raw/data-vault-raw
                cp data/raw/*.csv data/raw/data-vault-raw/
                
                echo "Você pode iniciar o ambiente com: docker-compose up -d"
                exit 0
            fi
            
            chmod 600 ~/.kaggle/kaggle.json
        fi
        
        # Baixar o conjunto de dados usando a API Kaggle
        echo "Baixando o conjunto de dados da Olist..."
        kaggle datasets download olistbr/brazilian-ecommerce -p data/raw || {
            echo "Falha ao baixar usando o Kaggle CLI."
            exit 1
        }
        
        # Renomear o arquivo baixado pelo Kaggle
        mv data/raw/brazilian-ecommerce.zip data/raw/olist_dataset.zip
    }
}

# Descompactar o arquivo
echo "Descompactando o arquivo..."
unzip -o data/raw/olist_dataset.zip -d data/raw || {
    echo "Erro ao descompactar o arquivo. Verificando se já existem arquivos CSV..."
    
    # Verificar se já existem arquivos CSV, caso contrário sair
    csv_count=$(ls -1 data/raw/*.csv 2>/dev/null | wc -l)
    if [ $csv_count -eq 0 ]; then
        echo "Nenhum arquivo CSV encontrado. Saindo..."
        exit 1
    else
        echo "Arquivos CSV já existem. Continuando..."
    fi
}

echo "Preparando os arquivos para o Minio..."

# Criar uma estrutura para o Minio
mkdir -p data/raw/data-vault-raw

# Copiar os arquivos CSV para a pasta que será mapeada para o Minio
cp data/raw/*.csv data/raw/data-vault-raw/

# Verificar se os arquivos essenciais existem, caso contrário criar dados de demonstração
for arquivo in olist_customers_dataset.csv olist_orders_dataset.csv olist_products_dataset.csv olist_sellers_dataset.csv olist_order_items_dataset.csv; do
    if [ ! -f "data/raw/$arquivo" ]; then
        echo "Arquivo $arquivo não encontrado. Criando versão de demonstração..."
        
        case $arquivo in
            olist_customers_dataset.csv)
                echo "customer_id,customer_unique_id,customer_zip_code_prefix,customer_city,customer_state" > data/raw/$arquivo
                echo "c1,cu1,12345,São Paulo,SP" >> data/raw/$arquivo
                echo "c2,cu2,23456,Rio de Janeiro,RJ" >> data/raw/$arquivo
                echo "c3,cu3,34567,Belo Horizonte,MG" >> data/raw/$arquivo
                ;;
                
            olist_orders_dataset.csv)
                echo "order_id,customer_id,order_status,order_purchase_timestamp,order_approved_at,order_delivered_carrier_date,order_delivered_customer_date,order_estimated_delivery_date" > data/raw/$arquivo
                echo "o1,c1,delivered,2018-01-01 10:00:00,2018-01-01 12:00:00,2018-01-02 10:00:00,2018-01-03 10:00:00,2018-01-10 10:00:00" >> data/raw/$arquivo
                echo "o2,c1,shipped,2018-01-02 10:00:00,2018-01-02 12:00:00,2018-01-03 10:00:00,,2018-01-15 10:00:00" >> data/raw/$arquivo
                echo "o3,c2,delivered,2018-01-03 10:00:00,2018-01-03 12:00:00,2018-01-04 10:00:00,2018-01-05 10:00:00,2018-01-12 10:00:00" >> data/raw/$arquivo
                ;;
                
            olist_products_dataset.csv)
                echo "product_id,product_category_name,product_name_length,product_description_length,product_photos_qty,product_weight_g,product_length_cm,product_height_cm,product_width_cm" > data/raw/$arquivo
                echo "p1,electronics,10,100,3,1000,30,10,20" >> data/raw/$arquivo
                echo "p2,furniture,15,150,5,5000,100,50,40" >> data/raw/$arquivo
                echo "p3,household,12,120,2,500,20,15,10" >> data/raw/$arquivo
                ;;
                
            olist_sellers_dataset.csv)
                echo "seller_id,seller_zip_code_prefix,seller_city,seller_state" > data/raw/$arquivo
                echo "s1,12345,São Paulo,SP" >> data/raw/$arquivo
                echo "s2,23456,Rio de Janeiro,RJ" >> data/raw/$arquivo
                echo "s3,34567,Belo Horizonte,MG" >> data/raw/$arquivo
                ;;
                
            olist_order_items_dataset.csv)
                echo "order_id,order_item_id,product_id,seller_id,shipping_limit_date,price,freight_value" > data/raw/$arquivo
                echo "o1,1,p1,s1,2018-01-05 10:00:00,100.0,10.0" >> data/raw/$arquivo
                echo "o1,2,p2,s2,2018-01-05 10:00:00,200.0,20.0" >> data/raw/$arquivo
                echo "o2,1,p3,s3,2018-01-06 10:00:00,50.0,5.0" >> data/raw/$arquivo
                echo "o3,1,p1,s1,2018-01-07 10:00:00,100.0,10.0" >> data/raw/$arquivo
                ;;
        esac
        
        # Copiar o arquivo criado para o diretório do Minio
        cp data/raw/$arquivo data/raw/data-vault-raw/
    fi
done

echo "Dataset preparado com sucesso!"
echo "Os arquivos estão disponíveis em data/raw/ e data/raw/data-vault-raw/"
echo "Você pode iniciar o ambiente com: docker-compose up -d"