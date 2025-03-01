FROM jupyter/pyspark-notebook:latest

USER root

# Instalar pacotes do sistema necessários
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    software-properties-common \
    ssh \
    wget \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Especificar diretamente o caminho do SPARK_HOME e criar pasta jars se não existir
RUN mkdir -p /usr/local/spark/jars

# Baixar JARs do S3 para o diretório correto
RUN wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar -P /usr/local/spark/jars/ && \
    wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar -P /usr/local/spark/jars/

# Configurar variáveis de ambiente do Spark
ENV PYTHONPATH=/usr/local/spark/python:/usr/local/spark/python/lib/py4j-0.10.9.5-src.zip:$PYTHONPATH
ENV PYSPARK_PYTHON=python3
ENV PYSPARK_DRIVER_PYTHON=python3

# Mudar para usuário jovyan (padrão do Jupyter)
USER jovyan

# Instalar pacotes Python necessários
RUN pip install --no-cache-dir \
    delta-spark==2.4.0 \
    pyspark==3.4.1 \
    pandas \
    pyarrow \
    matplotlib \
    seaborn \
    boto3 \
    s3fs

# Criar diretórios de trabalho
RUN mkdir -p /home/jovyan/notebooks /home/jovyan/data

# Configurar o Jupyter para aceitar conexões de qualquer IP
RUN jupyter notebook --generate-config && \
    echo "c.NotebookApp.ip = '0.0.0.0'" >> ~/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.open_browser = False" >> ~/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.token = ''" >> ~/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.password = ''" >> ~/.jupyter/jupyter_notebook_config.py

WORKDIR /home/jovyan

# Executar o Jupyter Notebook quando o container iniciar
CMD ["start-notebook.sh", "--NotebookApp.token=''", "--NotebookApp.password=''"]