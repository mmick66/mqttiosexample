# MQTT Example using iOS, Mosca and Paho #

This is a companion to http://karmadust.com/internet-of-things-with-ios-node-js-and-mqtt/

### Prerequisites ###

I use PM2 to run Node.js applications as I feel that it offers better control and logs that forever.

```
npm install pm2 -g
```

Install http-server to serve the index.html page that contains the Paho.js client

```
npm install http-server -g
```

### Installation ###

Clone the repo

```
git clone git@bitbucket.org:mmick66/mqttiosexample.git
```

Update the Node.js dependencies

```
cd mqttiosexample/broker
npm install # installs Mosca
cd ../
```

Update the iOS Pod dependencies

```
cd mqttiosexample/ios
pod install
cd ../
```

### Running the system ###

1. Start the broker
```
pm2 broker/broker.js
```

2. Start the http server
```
http-server ./web
```

3. Load http://localhost:8080/

4. Launch the iOS Simulator, press Connect, select Online from the tabs and press Send

5. Look at the webpage for the incoming output.
