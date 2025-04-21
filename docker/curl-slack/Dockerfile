## This should be a simple image to run slack hooks
##
## from ./curl-slack directory
#docker build --file Dockerfile -t public.ecr.aws/ct-nilus/base-images:curl-slack-v1 .
#aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/ct-nilus
##docker push <image_tag>
#
FROM curlimages/curl:latest
WORKDIR /
COPY ./slack-webhook.sh /slack-webhook.sh
USER root
RUN chmod 777 /slack-webhook.sh
#CMD tail -f /dev/null
CMD /bin/sh /slack-webhook.sh
