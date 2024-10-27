const http = require('http');

// const colors = ['red', 'blue', 'gray', 'blueviolet', 'aqua', 'khaki', 'coral'];
// const color = colors[Math.floor(Math.random() * colors.length)];

const sleep = ms => new Promise(r => {
    console.log("sleep for ", ms, " ms");
    return setTimeout(r, ms)
});

async function getData(url) {
    try {
        console.log("send request to ", url);
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`Response status: ${response.status}`);
        }

        const json = await response.json();
        return json;
    } catch (error) {
        console.error(error.message);
    }
}

http.createServer(async function (req, res) {
    console.log(process.env.MY_POD_IP, " received request: ", req.method, req.url, req.headers)

    let externalServers = [];

    const delaySimulation = process.env.SLEEP_DURATION || 0;
    await sleep(Math.floor(Math.random() * delaySimulation));

    if (process.env.EXTERNAL_SERVERS) {
        externalServers = process.env.EXTERNAL_SERVERS.split(" ");
    }

    let data = "";
    for (const url of externalServers) {
        const result = await getData(url);
        console.log("url ", url, "response: ", result);

        data += "\n" + JSON.stringify(result);
    }

    res.write("I am " + process.env.MY_POD_IP + " aggregated data: " + data);
    res.end();
}).listen(80); 
