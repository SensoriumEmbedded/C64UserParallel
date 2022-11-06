
//#include "draw01.prg.h"
#include "ember_head.prg.h"
//#include "disp_fract.prg.h"

#define STROBE_FLG_PIN 11   
#define READY_DA2_PIN  10   
#define UDB0_PIN        9   
#define UDB1_PIN        8   
#define UDB2_PIN        7   
#define UDB3_PIN        6   
#define UDB4_PIN        5   
#define UDB5_PIN        4   
#define UDB6_PIN        3   
#define UDB7_PIN        2   

uint8_t UDBbitpin[] = { UDB0_PIN, UDB1_PIN, UDB2_PIN, UDB3_PIN, UDB4_PIN, UDB5_PIN, UDB6_PIN, UDB7_PIN };

void setup() 
{
  Serial.begin(115200);
  
  pinMode(STROBE_FLG_PIN, INPUT);  //open collector (pulled up in C64)
  digitalWrite(STROBE_FLG_PIN, 0);  //low when output
  
  pinMode(READY_DA2_PIN, INPUT);
  
  for(uint8_t bitnum = 0; bitnum < 8; bitnum++) pinMode(UDBbitpin[bitnum], OUTPUT);
  SetParallel(0);

  Serial.println("\n\nTrav's C64 User Port Project");
} 
  
void loop()
{
  while (Serial.available()) Serial.read(); //read all
  Serial.println("\nReady to send...");
  while (!Serial.available()); //wait for char
   
  uint32_t StartMillis = millis();

  WriteByte(0xb9); //magic number to start
  WriteByte(0x01); //StartAddr Low
  WriteByte(0x08); //StartAddr High
  
  uint8_t NumPages = sizeof(file_prg)/256+1;
  WriteByte(NumPages);
  Serial.printf("Sending %d bytes\n", NumPages*256);
  
  uint16_t bytenum = 0;
  while(bytenum < sizeof(file_prg)) WriteByte(file_prg[bytenum++]);
  
  while(bytenum++ < NumPages *256) WriteByte(0); //pad with zeros
  // 11/6/22:  64 bytes takes ~2.5mS, 204800bps!
  
  Serial.printf("File Sent, took %dmS\n", millis() - StartMillis);
}  
  
void WriteByte(uint8_t val)
{
  while (!digitalRead(READY_DA2_PIN)); //wait for ready
  SetParallel(val);
  pinMode(STROBE_FLG_PIN, OUTPUT);  //drive low open collector
  //digitalWrite(STROBE_FLG_PIN, 0);
  while (digitalRead(READY_DA2_PIN)); //wait for not ready
  pinMode(STROBE_FLG_PIN, INPUT);  //float high open collector
  //digitalWrite(STROBE_FLG_PIN, 1);

} 
  
void SetParallel(uint8_t val)
{
  for(uint8_t bitnum = 0; bitnum < 8; bitnum++) digitalWrite(UDBbitpin[bitnum], val & (1<<bitnum));
}

