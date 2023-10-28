FROM node:18
RUN useradd -d /home/challenge -m -s /bin/bash challenge

WORKDIR /home/challenge

COPY package*.json ./
RUN npm install

# Bundle app source
COPY flag.txt .
COPY index.html .
COPY index.js .
RUN chmod -R 755 /home/challenge
RUN chmod 444 /home/challenge/flag.txt
RUN chown -R root:root /home/challenge
USER challenge
EXPOSE 3000
CMD [ "node", "index.js" ]