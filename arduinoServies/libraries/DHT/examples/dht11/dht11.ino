#include<dht.h>
dht DHT;
#define DHT11_PIN 3

float temp;
float hum;

void setup(){
Serial.begin(9600);  
}

void loop(){
  DHT.read11(DHT11_PIN);
  temp=DHT.temperature;
  hum=DHT.humidity;
  Serial.print(temp);
  Serial.print("    ");
  Serial.println(hum);
  delay(200);
}
