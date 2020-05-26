using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;

namespace CsharpController
{
    class Program
    {
        static void Main(string[] args)
        {
            string ip = "192.168.0.16";
            var ipbytes = ip.Split(".").Select(oct => byte.Parse(oct)).ToArray();
            IPAddress ipAddr = new IPAddress(ipbytes);
            IPEndPoint localEndPoint = new IPEndPoint(ipAddr, 11111);

            // Creation TCP/IP Socket using  
            // Socket Class Costructor 
            Socket listener = new Socket(ipAddr.AddressFamily,
                         SocketType.Stream, ProtocolType.Tcp);

            List<Socket> input = new List<Socket> { listener };

            try
            {

                // Using Bind() method we associate a 
                // network address to the Server Socket 
                // All client that will connect to this  
                // Server Socket must know this network 
                // Address 
                listener.Bind(localEndPoint);

                // Using Listen() method we create  
                // the Client list that will want 
                // to connect to Server 
                listener.Listen(10);

                Console.WriteLine("Waiting connection ... ");
                while (true)
                {
                    var tempinput = new List<Socket>(input);
                    Socket.Select(tempinput, null, null, -1);

                    foreach (var sock in tempinput)
                    {
                        if (sock == listener)
                        {
                            // Suspend while waiting for 
                            // incoming connection Using  
                            // Accept() method the server  
                            // will accept connection of client 
                            Socket clientSocket = listener.Accept();
                            input.Add(clientSocket);
                            Console.WriteLine("got client");
                        }
                        else
                        {
                            // Data buffer 
                            byte[] bytes = new Byte[1024];

                            int numByte = sock.Receive(bytes);

                            var value = Encoding.UTF8.GetString(bytes, 0, numByte);

                            if (!string.IsNullOrEmpty(value))
                            {
                                Externals.log(value);
                            }
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Console.WriteLine(e.ToString());
            }
        }
    }
}
