FROM mcr.microsoft.com/azure-cli:2.3.1

ENV TERRAFORM_VERSION=0.12.23

RUN curl -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip &&\
    unzip /tmp/terraform.zip &&\
    mv terraform /bin &&\
    chmod 0755 /bin/terraform &&\
    rm /tmp/terraform.zip

ADD entrypoint.sh /entrypoint.sh

RUN ["chmod", "+x", "/entrypoint.sh"]

ENTRYPOINT [ "/entrypoint.sh" ]
