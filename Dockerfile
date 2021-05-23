FROM jupyterhub/jupyterhub:latest
 
RUN apt-get update && apt-get -y upgrade && \
  apt-get install -y python3 python3-pip npm nodejs libnode64 sudo && \
  python3 -m pip install --upgrade notebook jupyter jupyterlab && \
  npm install -g configurable-http-proxy && \
  apt-get clean
  
RUN useradd admin -m && \
  usermod --password $(echo "admin" | openssl passwd -1 -stdin) admin && \
  mkdir -p /home/admin/notebook && \
  chmod 700 /home/admin && \
  chown -R admin: /home/admin && \
  usermod -a -G sudo admin
  
RUN useradd user1 -m && \
  usermod --password $(echo "user1" | openssl passwd -1 -stdin) user1 && \
  mkdir -p /home/user1/notebook && \
  chmod 700 /home/user1 && \
  chown -R user1: /home/user1
  
COPY jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py
COPY jupyter_notebook_config.py /usr/etc/jupyter/jupyter_notebook_config.py