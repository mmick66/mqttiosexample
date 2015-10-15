# MQTT Example using iOS, Mosca and Paho #

This is a companion to http://karmadust.com/internet-of-things-with-ios-node-js-and-mqtt/

## Prerequisites

I use PM2 to run Node.js applications as I feel that it offers better control and logs that forever.

```
npm install pm2 -g
```

Install http-server to serve the index.html page that contains the Paho.js client

```
npm install http-server -g
```

## Installation of Dependencies

Clone the repo

```
git clone git@bitbucket.org:mmick66/mqttiosexample.git
```

### Update the Node.js dependencies

```
cd /broker
npm install # mainly Mosca
cd ../
```

### Update the iOS Pod dependencies

In the **/ios** sub-folder:

```
cd /ios
pod install
cd ../
```

If pod seems to run forever you can try the following:

```
pod repo remove master
pod setup
pod install --verbose # see what is happening
```

## Running the system

First make sure that a **MongoDB Instance** is running locally at port 27017. If **not** then run 

```
mkdir -p mongo/db
mkdir mongo/logs
touch mongo/logs/log.txt
mongod --dbpath ./mongo/db --logpath ./mongo/logs/log.txt --fork
```


Then, from the root folder:

1. Start the broker
```
pm2 start broker/broker.js
```

2. Start the http server
```
http-server ./web
```

3. Load http://localhost:8080/

4. Launch the iOS Simulator, press Connect, select Online from the tabs and press Send

5. Look at the webpage for the incoming output.
