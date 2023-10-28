const express = require('express');
const request = require('request');
const bodyParser = require('body-parser');
const fs = require('fs');
const parseUrl = require("parse-url"); 
const app = express();


app.use(bodyParser.json());

const items = {"items":[{"name":"Tent", "price": 150.00}, {"name":"Sleeping Bag", "price": 100.00}, {"name": "Hatchet", "price": 50.00}]}; 

app.get('/', (req, res) => {
    res.sendFile(__dirname + "/index.html");
});
app.get('/api', (req, res) => {
    let endpoints = {
        "public": {
            "/api/items":{
                "GET": "Returns the current added items",
                "POST": 'Add items in following format: {"name":"New Item", "price":90.00}'
            },
            "/api/check_connection":{
                "POST": "Check connection to the outward internet! Will return page data if under 100 characters."
            },
            "/api/flag_status":{
                "GET": "Check on the flag"
            }
        },
        "private":{
            "/api/flag":{
                "GET": "Nice and safe"
            }
        }
    }

    res.json(endpoints); 
});
app.get('/api/items', (req, res) => {
    res.json(items); 
});
app.post('/api/items', (req, res) => {
    
    const req_data = req.body; 
    let item_name = req_data.name;
    let item_price = req_data.price;
    if (typeof item_name === 'string' && typeof item_price === 'number') {


        items.items.push({"name":item_name,"price":item_price});
        res.send("Added!");
    } else {
        res.send('Invalid data format: name must be a string and price must be a number');
        
    }
    
});

app.post('/api/check_connection', (req, res) => {
    const req_data = req.body; 
    let url = req_data.url;

    try{
        parsed = parseUrl(url)
        if (parsed.resource == '127.0.0.1'){
            res.send("Hey... I said check connection to outward internet. What kinda funny business are you up to?\n Protected by: parse-url\n");
        }else{
            request(url, (error, response, body) => {
                if (error) {
                  res.send("OOP, looks like we might have a problem.\n");
                } else {
                  const statusCode = response.statusCode;
                  if (body.length > 100) {
                    
                  res.send("Status Code: " + statusCode +"\n ");
                  } else {

                  res.send("Status Code: " + statusCode +"\nSite Data:\n" +body +"\n");
                  }
                
                }
            });
        }
    } catch (error) {
        res.status(400).json({ success: false, message: 'Error parsing URL' });
    }
    
    
});
app.get('/api/flag_status', (req, res) => {
    res.send("Yep! It's still there, safe and sound.")
});

app.get('/api/flag',  (req, res) => {
    var url = req.protocol + '://' + req.get('host') + req.originalUrl;
    try{
        parsed = parseUrl(url)
        if (parsed.resource != '127.0.0.1'){
            res.send("Hey... what's going on here\n");
        }else{
            fs.readFile("./flag.txt", 'utf8', (err, data) => {
                if (err) {
                    res.send("There was an error and this is sad :(\n")
            
                }else{
                    res.send(data+"\n")
                }
            });
    }} catch (error) {
        res.status(400).json({ success: false, message: 'Error parsing URL' });
    }
      
});

const PORT = 3000;

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});