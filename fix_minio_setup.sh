#!/bin/bash

# Script para configurar corretamente o Minio e garantir que os arquivos estejam disponíveis

echo "Iniciando configuração do Minio e preparação dos dados..."

# Verificar se o Minio está rodando
echo "Verificando se o Minio está em execução..."
if ! docker ps | grep -q minio; then
    echo "ERRO: Contêiner do Minio não está rodando!"
    echo "Execute 'docker-compose up -d' para iniciar todos os serviços."
    exit 1
fi

# Verificar se temos os arquivos de dados
echo "Verificando arquivos de dados..."
if [ ! -d "data/raw" ] || [ ! "$(ls -A data/raw/*.csv 2>/dev/null)" ]; then
    echo "Criando dados de exemplo..."
    mkdir -p data/raw
    
    # Criar arquivos de exemplo
    echo "customer_id,customer_unique_id,customer_zip_code_prefix,customer_city,customer_state" > data/raw/olist_customers_dataset.csv
    echo "c1,cu1,12345,São Paulo,SP" >> data/raw/olist_customers_dataset.csv
    echo "c2,cu2,23456,Rio de Janeiro,RJ" >> data/raw/olist_customers_dataset.csv
    echo "c3,cu3,34567,Belo Horizonte,MG" >> data/raw/olist_customers_dataset.csv
    
    echo "order_id,customer_id,order_status,order_purchase_timestamp,order_approved_at,order_delivered_carrier_date,order_delivered_customer_date,order_estimated_delivery_date" > data/raw/olist_orders_dataset.csv
    echo "o1,c1,delivered,2018-01-01 10:00:00,2018-01-01 12:00:00,2018-01-02 10:00:00,2018-01-03 10:00:00,2018-01-10 10:00:00" >> data/raw/olist_orders_dataset.csv
    echo "o2,c1,shipped,2018-01-02 10:00:00,2018-01-02 12:00:00,2018-01-03 10:00:00,,2018-01-15 10:00:00" >> data/raw/olist_orders_dataset.csv
    echo "o3,c2,delivered,2018-01-03 10:00:00,2018-01-03 12:00:00,2018-01-04 10:00:00,2018-01-05 10:00:00,2018-01-12 10:00:00" >> data/raw/olist_orders_dataset.csv
    
    echo "product_id,product_category_name,product_name_length,product_description_length,product_photos_qty,product_weight_g,product_length_cm,product_height_cm,product_width_cm" > data/raw/olist_products_dataset.csv
    echo "p1,electronics,10,100,3,1000,30,10,20" >> data/raw/olist_products_dataset.csv
    echo "p2,furniture,15,150,5,5000,100,50,40" >> data/raw/olist_products_dataset.csv
    echo "p3,household,12,120,2,500,20,15,10" >> data/raw/olist_products_dataset.csv
    
    echo "seller_id,seller_zip_code_prefix,seller_city,seller_state" > data/raw/olist_sellers_dataset.csv
    echo "s1,12345,São Paulo,SP" >> data/raw/olist_sellers_dataset.csv
    echo "s2,23456,Rio de Janeiro,RJ" >> data/raw/olist_sellers_dataset.csv
    echo "s3,34567,Belo Horizonte,MG" >> data/raw/olist_sellers_dataset.csv
    
    echo "order_id,order_item_id,product_id,seller_id,shipping_limit_date,price,freight_value" > data/raw/olist_order_items_dataset.csv
    echo "o1,1,p1,s1,2018-01-05 10:00:00,100.0,10.0" >> data/raw/olist_order_items_dataset.csv
    echo "o1,2,p2,s2,2018-01-05 10:00:00,200.0,20.0" >> data/raw/olist_order_items_dataset.csv
    echo "o2,1,p3,s3,2018-01-06 10:00:00,50.0,5.0" >> data/raw/olist_order_items_dataset.csv
    echo "o3,1,p1,s1,2018-01-07 10:00:00,100.0,10.0" >> data/raw/olist_order_items_dataset.csv
    
    echo "Dados de exemplo criados com sucesso!"
fi

# Cria diretório para bucket do Minio
mkdir -p data/minio_data

# Configurar o bucket do Minio diretamente usando a CLI do Minio
echo "Configurando o Minio com Docker..."

# Criar um contêiner temporário para a CLI do Minio
docker run --rm --network $(docker inspect -f '{{.HostConfig.NetworkMode}}' minio) \
  -v $(pwd)/data/raw:/data \
  --entrypoint /bin/sh \
  minio/mc -c "
    mc config host add myminio http://minio:9000 minioadmin minioadmin && 
    mc mb --ignore-existing myminio/data-vault-raw && 
    mc cp /data/* myminio/data-vault-raw/ && 
    mc policy set download myminio/data-vault-raw"

echo "Concluído! O bucket data-vault-raw foi criado no Minio e os arquivos foram copiados."
echo "Agora vamos verificar se os arquivos estão acessíveis através do S3..."

# Verifica se temos os JARs necessários para o S3A
mkdir -p hadoop_jars
if [ ! -f "hadoop_jars/hadoop-aws-3.3.4.jar" ]; then
    echo "Baixando os JARs necessários para o S3A..."
    wget -O hadoop_jars/hadoop-aws-3.3.4.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar
    wget -O hadoop_jars/aws-java-sdk-bundle-1.12.262.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar
    echo "JARs baixados com sucesso!"
fi

echo "Reiniciando o Jupyter para aplicar as mudanças..."
docker restart jupyter

echo "Configuração concluída!"
echo "Agora você pode acessar o Jupyter e executar o notebook com a integração Minio."
echo "Acesse http://localhost:8888 para continuar."