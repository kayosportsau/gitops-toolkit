FROM sajid2045/conda-base

RUN conda install -y nb_conda_kernels
RUN conda create -y -n py27 python=2.7 ipykernel
RUN conda create -y -n awscli python=3.6.3 ipykernel
RUN conda create -y -n sceptre python=3.6.3 ipykernel

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN conda init bash
RUN source /root/.bashrc && conda activate awscli && conda install -y -c conda-forge awscli && conda install -y -c conda-forge/label/gcc7 awscli && conda install -y -c conda-forge/label/cf201901 awscli
RUN source /root/.bashrc && conda activate awscli && pip install taskcat
RUN source /root/.bashrc && conda activate sceptre && pip install sceptre

#Versions
ARG KUBECTL_VERSION="1.12.7/2019-03-27"
ARG HELM_VERSION="2.14.0"
ARG HELM_TILLER_VERSION="0.6.7"
ARG HELM_DIFF_VERSION="v2.11.0+3"
ARG KUBECTX_VERSION="0.6.3"
ARG VELERO_VERSION="0.11.0"


RUN mkdir /downloads 
WORKDIR "/downloads"


#kubectl
RUN curl -L https://amazon-eks.s3-us-west-2.amazonaws.com/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    curl -L https://amazon-eks.s3-us-west-2.amazonaws.com/${KUBECTL_VERSION}/bin/linux/amd64/aws-iam-authenticator -o /usr/local/bin/aws-iam-authenticator && \
    chmod +x /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/aws-iam-authenticator

#helm
RUN curl -L https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz -o /tmp/helm.tar.gz && \
    tar -xvzf /tmp/helm.tar.gz -C /tmp && \
    mv /tmp/linux-amd64/helm /usr/local/bin/helm && \
    mv /tmp/linux-amd64/tiller /usr/local/bin/tiller && \
    chmod +x /usr/local/bin/helm && \
    chmod +x /usr/local/bin/tiller && \
    helm init -c && \
    helm plugin install https://github.com/rimusz/helm-tiller --version ${HELM_TILLER_VERSION}  && \
    helm plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION} && \
    helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator && \
    rm -rf /tmp/*

# INSTALL EKSCTL
ARG EKSCTL_VERSION=latest_release
RUN curl --location "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
RUN mv /tmp/eksctl /usr/local/bin

# heptio-authenticator-aws
RUN wget https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator 
RUN cp -v aws-iam-authenticator /usr/local/bin/heptio-authenticator-aws && cp -v aws-iam-authenticator /usr/local/bin/aws-iam-authenticator
RUN chmod +x /usr/local/bin/heptio-authenticator-aws && chmod +x /usr/local/bin/aws-iam-authenticator

RUN echo "source /etc/bash_completion" >> /root/.bashrc
RUN echo "complete -C '/usr/local/bin/aws_completer' aws" >> /root/.bashrc
RUN eksctl completion bash > /root/.eksctl_completion && echo "source /root/.eksctl_completion" >> /root/.bashrc 

#Install JX 
ARG JX_VERSION=v2.0.420
RUN mkdir -p ~/.jx/bin
RUN curl -L https://github.com/jenkins-x/jx/releases/download/$JX_VERSION/jx-linux-amd64.tar.gz | tar xzv -C ~/.jx/bin
RUN export PATH=$PATH:/root/.jx/bin
RUN echo 'export PATH=$PATH:/root/.jx/bin' >> /root/.bashrc
RUN echo "source <(kubectl completion bash)" >> /root/.bashrc 
RUN echo "source <(jx completion bash)" >> /root/.bashrc 

#install kustomize
ARG KUSTOMIZE_VERSION=2.0.3
RUN curl -O -L https://github.com/kubernetes-sigs/kustomize/releases/download/v${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64
# RUN curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest | grep browser_download | grep linux |cut -d '"' -f 4 | xargs curl -O -L
RUN mv kustomize_${KUSTOMIZE_VERSION}_linux_amd64 /usr/local/bin/kustomize && chmod +x /usr/local/bin/kustomize

#kubetail
RUN wget https://raw.githubusercontent.com/johanhaleby/kubetail/master/kubetail && chmod +x kubetail && mv kubetail /usr/local/bin 

# ksonet
ARG KSONNET_VERSION=0.13.1
RUN wget https://github.com/ksonnet/ksonnet/releases/download/v${KSONNET_VERSION}/ks_${KSONNET_VERSION}_linux_amd64.tar.gz && \
    tar -xzf ks_${KSONNET_VERSION}_linux_amd64.tar.gz && chmod +x ks_${KSONNET_VERSION}_linux_amd64/ks && cp -v ks_${KSONNET_VERSION}_linux_amd64/ks /usr/local/bin/

#argo
ARG ARGO_VERSION=v1.1.1
RUN wget https://github.com/argoproj/argo-cd/releases/download/${ARGO_VERSION}/argocd-linux-amd64 && chmod +x argocd-linux-amd64 && mv argocd-linux-amd64 /usr/local/bin/argo


#kubectx
RUN curl -L https://github.com/ahmetb/kubectx/archive/v${KUBECTX_VERSION}.tar.gz -o /tmp/kubectx.tar.gz && \
    tar -xvzf /tmp/kubectx.tar.gz -C /tmp && \
    mv /tmp/kubectx-${KUBECTX_VERSION}/kubectx /usr/local/bin/kubectx && \  
    mv /tmp/kubectx-${KUBECTX_VERSION}/kubens /usr/local/bin/kubens && \  
    chmod +x /usr/local/bin/kubectx && \  
    chmod +x /usr/local/bin/kubens && \  
    mv /tmp/kubectx-${KUBECTX_VERSION}/completion/kubectx.bash /usr/share/bash-completion/completions/kubectx.bash && \  
    mv /tmp/kubectx-${KUBECTX_VERSION}/completion/kubens.bash /usr/share/bash-completion/completions/kubens.bash && \
    rm -rf /tmp/*


#velero
RUN curl -L https://github.com/heptio/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz -o /tmp/velero.tar.gz && \
    tar -xvzf /tmp/velero.tar.gz -C /tmp && \
    mv /tmp/velero /usr/local/bin/velero && \
    chmod +x /usr/local/bin/velero && \
    rm -rf /tmp/*

# #istioctl
# ARG ISTIO_VERSION=1.1.8
# RUN mkdir /istio/ && cd /istio/ curl -L https://git.io/getLatestIstio |  sh -    
# RUN cd /istio/istio-${ISTIO_VERSION} &&  cp  bin/istioctl /usr/local/bin/ 
# # RUN rm -rf istio-${ISTIO_VERSION}


#Install Hub

RUN curl -L https://github.com/github/hub/releases/download/v2.12.1/hub-linux-amd64-2.12.1.tgz  -o /tmp/hub.tar.gz && \
    tar -xvzf /tmp/hub.tar.gz -C /tmp && mv /tmp/hub-linux-* /usr/local/hub-linux 
RUN echo 'export PATH=$PATH:/usr/local/hub-linux/bin' >> /root/.bashrc    


RUN pip install mkdocs

RUN conda clean --all --yes
RUN rm -rf /downloads/ && rm -rf /tmp/eksctl

RUN echo "alias dep='kubectl get deploy'" >> /root/.bashrc
RUN echo "alias ing='kubectl get ing'" >> /root/.bashrc
RUN echo "alias svc='kubectl get svc'" >> /root/.bashrc
RUN echo "alias pods='kubectl get pods'" >> /root/.bashrc
RUN echo "alias k=kubectl" >> /root/.bashrc
RUN echo 'alias ap="kubectl get pods --all-namespaces"' >> /root/.bashrc
RUN echo "alias po='kubectl get pods'" >> /root/.bashrc
RUN echo "export LC_ALL=C.UTF-8" >> /root/.bashrc
RUN echo "export LANG=C.UTF-8"   >> /root/.bashrc
RUN echo "export USER=root" >> /root/.bashrc
RUN echo "conda activate awscli" >> /root/.bashrc

RUN git config --global alias.co checkout
RUN git config --global alias.br branch
RUN git config --global alias.st status

ADD dev-cheats /root/dev-cheats
RUN echo 'export PATH=$PATH:/root/dev-cheats/' >> /root/.bashrc

# ADD conda-profile.sh /usr/local/etc/profile.d/conda.sh
# RUN echo ". /usr/local/etc/profile.d/conda.sh" >> /root/.bashrc

ADD json2yaml /usr/local/bin/json2yaml
RUN chmod +x /usr/local/bin/json2yaml

# cmd okta-utils
ADD okta-utils/* /usr/local/bin/
RUN pip install --no-cache-dir -r /usr/local/bin/okta-utils-requirements.txt



WORKDIR "/src"
CMD /bin/bash
