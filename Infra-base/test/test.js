  const { Client } = require("@heroiclabs/nakama-js");
  const WebSocket = require("ws");
  global.WebSocket = WebSocket;

  const client = new Client("defaultkey", "127.0.0.1", "7350", false);

  async function runPlayer(username) {
    const session = await client.authenticateEmail(`${username}@test.com`, "password", true, username);
    console.log("Logged in:", username);

    const socket = client.createSocket(false, false);
    await socket.connect(session, true);

    // Event 1: Standard Matchmaking Match (Happens first)
    socket.onmatchmakermatched = (matched) => {
      console.log(`🤝 ${username} matched! Ticket: ${matched.ticket}`);
    };

    // Event 2: Custom Notification (Contains your Agones IP/Port)
    socket.onnotification = (notification) => {
      if (notification.code === 1) { 
        // notification.content is already a JSON object
        const { host, port } = notification.content;
        console.log(`🚀 ${username} RECEIVED SERVER DETAILS!`);
        console.log(`>>> CONNECT TO: ${host}:${port}`);
      }
    };

    await socket.addMatchmaker("*", 2, 2);
    console.log(username, "joined matchmaking");
  }

  (async () => {
    runPlayer("player1");
    setTimeout(() => runPlayer("player2"), 1000);
  })();