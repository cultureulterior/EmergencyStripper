/* 
 * Makes a moving color sweep on an
 * Addressable RGB LED Strip
 *
 * To use this, you will need to plug an Addressable RGB LED
 * strip into (DATA pin 12, and GND pin GND)
 */
 
#include <PololuLedStrip.h>

// Create an ledStrip object and specify the pin it will use.
PololuLedStrip<12> ledStrip;

// Create a buffer for holding the colors (3 bytes per color).
#define LED_COUNT 60
rgb_color colors[LED_COUNT];
rgb_color current_color;
rgb_color recieved_color;
unsigned char recieved_checksum;
unsigned char calculated_checksum;
int message_length = 4;
unsigned long last_correct = 0;
unsigned long time = 0;

void setup()
{
  Serial.begin(115200);  
  current_color = (rgb_color){0,0,255};
  Serial.println("Ready to receive colors."); 
}

void loop()
{
  // Update the colors.
  //uint16_t time = millis() ;
  time = millis();
  if((time - last_correct) > 60000)
  {
    current_color = (rgb_color){0,0,255};
    Serial.println("Data too old");
  }
  for(uint16_t i = 0; i < LED_COUNT; i++)
  {    
    byte slow = (time >> 5) - (i << 3);    
    byte pulse = (byte)(64.0*(sin(((float) slow)/(3.14/2.0))+1.5));
    colors[i] = (rgb_color){
      (int)pulse*(int)current_color.red/(int)255,
      (int)pulse*(int)current_color.green/(int)255,
      (int)pulse*(int)current_color.blue/(int)255
    };
  }
  ledStrip.write(colors, LED_COUNT);  
  
  if (Serial.available()>=4)
  {
    byte header = Serial.read();
    if(header != 32)
    {
      byte next = 0;
      for (int reparse = 0; reparse < 4; reparse++) {
        next = Serial.peek();
        if(next == 32)
          {break;}
        else
          {Serial.read();}
      }
      if(next == 32)
         {Serial.println("Error- resynchronized");}
      else
         {Serial.println("Error- unable to resynchronize");}
    }
    else
    {
      recieved_color.red = Serial.read();
      recieved_color.green = Serial.read();
      recieved_color.blue = Serial.read();
      recieved_checksum = Serial.read();   
      Serial.print("Recieved color:");     
      Serial.print(recieved_color.red,HEX);
      Serial.print(recieved_color.green,HEX);
      Serial.print(recieved_color.blue,HEX); 
      Serial.println(recieved_checksum,HEX);
      calculated_checksum = recieved_color.red ^ recieved_color.green ^ recieved_color.blue;
      if(calculated_checksum == recieved_checksum)
      {
        last_correct = millis();
        current_color.red = recieved_color.red;
        current_color.green = recieved_color.green;
        current_color.blue = recieved_color.blue;
      }
      else
      {
        Serial.print("Recieved wrong checksum:"); 
        Serial.print(calculated_checksum,HEX);
      }
    }
  }  
}
