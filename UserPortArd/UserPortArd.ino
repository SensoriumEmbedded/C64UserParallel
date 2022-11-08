
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
  
  for(uint8_t bitnum = 0; bitnum < 8; bitnum++) 
  {
     pinMode(UDBbitpin[bitnum], OUTPUT);
     digitalWrite(UDBbitpin[bitnum], 0);
  }

  Serial.print("Trav's PC->C64 File Transfer\n");
} 
  
void loop()
{
  uint8_t bytein;
  
  do 
  {
     Serial.print("\nClearing buffer\n");
     uint32_t BytesCleared = 0;
     while (SerialAvailabeTimeout(false)) //read all until timeout
     {
        Serial.read(); 
        BytesCleared++;
     }
     if (BytesCleared) Serial.printf("%d bytes cleared\n", BytesCleared);
     Serial.print("Waiting for Host...\n");
     while (!Serial.available()); //wait for start token (no timeout)
     bytein = Serial.read();
  } while (bytein != 0x64);   //start token
  
  TransferFile();
}  
  
void WriteByte(uint8_t val)
{
  while (!digitalRead(READY_DA2_PIN)); //wait for ready
  for(uint8_t bitnum = 0; bitnum < 8; bitnum++) digitalWrite(UDBbitpin[bitnum], val & (1<<bitnum));  //place byte on output
  pinMode(STROBE_FLG_PIN, OUTPUT);  //drive low open collector
  while (digitalRead(READY_DA2_PIN)); //wait for not ready
  pinMode(STROBE_FLG_PIN, INPUT);  //float high open collector
} 

bool SerialAvailabeTimeout(bool DispTOMsg)
{
  uint32_t StartTOMillis = millis();
  
  while(!Serial.available() && (millis() - StartTOMillis) < 500); // timeout loop
  if (Serial.available()) return(true);
  if (DispTOMsg) Serial.print("Timeout!\n");  
  return(false);
}

void TransferFile()
{ //start token has been received
  uint32_t StartSendMillis = millis();

  if(!SerialAvailabeTimeout(true)) return;
  uint16_t len = Serial.read();
  len = len + 256 * Serial.read();

  WriteByte(0xb9); //magic number to start
 
  uint8_t NumPages = len/256+1; //reound up to nearest 256 byte page
  WriteByte(NumPages);
  
  uint16_t bytenum = 0;
  while(bytenum++ < len)
  {
     if(!SerialAvailabeTimeout(true)) return;
     WriteByte(Serial.read());
  }  
  //TODO: Fix this onthe C64 side so  +3 isn't needed...
  while(bytenum++ < NumPages *256 + 3) WriteByte(0); //pad with zeros, 2 extra bytes to make up for address at start
  
  StartSendMillis = millis() - StartSendMillis;
  Serial.printf("Complete!\nTransfered %d bytes in %dmS\n", NumPages*256, StartSendMillis);
  uint32_t Rate = NumPages*256*1000*8/StartSendMillis;
  Serial.printf("  %d bytes per second\n", Rate/8);
  Serial.printf("  %d bits per second\n", Rate);  
}

