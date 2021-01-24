''' Libraries'''
from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient
import requests


''' Global Variables'''
#Device name
deviceName='labIoTGGroup_Core'
#certificate Path
certPath = 'certificates/certificate.pem.crt'
#key path
keyPath = 'certificates/private.pem.key'
#caPath
caPath = "certificates/ggc-CA.ca"
#root caPath
rootcaPath = "certificates/root.ca.pem"
#Used to loop through all Connectivity options from GG Core
ggCoreConnectivityCount = 0
#publish topic
topic = 'greengrass/telemetry'
#MQTT Client
myAWSIoTMQTTClient = None
#QoS
QoS = 0
#Connection Status
connectionStatus = False
#endpoint address
endpoint = "abno170pso3ez-ats.iot.us-east-2.amazonaws.com"


''' Methods'''
# Function to publish payload to MQTT topic
def publishToIoTTopic(myAWSIoTMQTTClient):
    while True:
        payload = input("Enter to send message: ")
        myAWSIoTMQTTClient.publish(topic, "This message is from the edge device", QoS)
        
def onMessageCallback(client, userdata, message):
    print("Message received on topic " + message.topic + ": " + message.payload.decode())

# Function to initialise MQTT client
def MQTT_Connect(host,port):
    print(host,port)
    myAWSIoTMQTTClient = AWSIoTMQTTClient(deviceName)
    myAWSIoTMQTTClient.configureEndpoint(host, port)
    myAWSIoTMQTTClient.configureCredentials(caPath, keyPath, certPath)
    myAWSIoTMQTTClient.configureMQTTOperationTimeout(5)
    connectionStatus =  myAWSIoTMQTTClient.connect()
    if connectionStatus:
        print("Client connected to greengrass core device")
        #myAWSIoTMQTTClient.subscribe(topic,0,onMessageCallback)
        publishToIoTTopic(myAWSIoTMQTTClient)
    else:
        print("Failed to connect")

MQTT_Connect("192.168.1.151",8883)

if connectionStatus:
    print("MQTT connection disconnected")


