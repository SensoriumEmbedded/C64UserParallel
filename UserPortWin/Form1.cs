
/*
 * Serial datalogger and RTC setting utility
 * 
 * Written by Travis Smith 2010, trav@tnhsmith.net
 *  
 */

using System;
using System.IO;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.IO.Ports;

namespace Serial_Logger
{
    public partial class Form1 : Form
    {
        volatile bool USBLost = false;

        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            serialPort1.ReadTimeout = 250;

        }

        private void timer1_Tick(object sender, EventArgs e)
        {
            string strMsg;

            if (USBLost)
            {
                try
                {
                    serialPort1.Open();
                    USBLost = false;
                    WriteToOutput("\nWe're back!", Color.DarkGreen);
                }
                catch
                {
                    rtbOutput.AppendText(".");
                    rtbOutput.Refresh();
                    return;
                }
            }

            try
            {
                while (serialPort1.BytesToRead != 0)
                {
                    strMsg = ">";
                    try
                    {
                        strMsg += serialPort1.ReadLine();
                    }
                    catch
                    {
                        strMsg += "***";  //timeout indicator
                        while (serialPort1.BytesToRead != 0)
                        {
                            strMsg += (char)serialPort1.ReadChar();
                        }
                        strMsg += "\r";
                        rtbOutput.SelectionColor = Color.Red;
                    }
                    WriteToOutput(strMsg, Color.Blue);
                }
            }
            catch
            {
                WriteToOutput("USB port disconnected, retrying...", Color.DarkRed);
                USBLost = true;
                return;
            }

        }

        private void btnConnected_Click(object sender, EventArgs e)
        {
            if (btnConnected.Text == "Connected")
            {   //disconnect:
                timer1.Enabled = false;
                //if (USBLost == false) 
                try
                {
                    serialPort1.Close();
                }
                catch
                {
                    MessageBox.Show("Unable to close " + tbComPort.Text, "Error");
                }
                btnConnected.Text = "Not Connected";
                btnConnected.BackColor = Color.Yellow;
                btnSendFile.Enabled = false;
            }
            else
            {   //connect
                serialPort1.PortName = tbComPort.Text;
                try
                {
                    rtbOutput.Clear();
                    serialPort1.Open();
                    serialPort1.Write("x"); //send wrong token to reset
                }
                catch
                {
                    MessageBox.Show("Unable to open " + tbComPort.Text, "Error");
                    return;
                }
                btnConnected.Text = "Connected";
                btnConnected.BackColor = Color.LightGreen;
                btnSendFile.Enabled = true;
                USBLost = false;
                timer1.Enabled = true;
            }
        }

        private void btnSendFile_Click(object sender, EventArgs e)
        {

            openFileDialog1.FileName = "";
            openFileDialog1.Filter = "PRG files (*.prg)|*.prg";
            if (openFileDialog1.ShowDialog() == DialogResult.Cancel) return;

            //WriteToOutput("Pinging device/C64", Color.Black);

            WriteToOutput("Sending info", Color.Black);

            //open file, get length
            BinaryReader br = new BinaryReader(File.Open(openFileDialog1.FileName, FileMode.Open));
            int len = (int)br.BaseStream.Length;
            
            //WriteToOutput("Transferring " + len + " bytes...", Color.Black);
            byte[] buf = new byte[len];


            byte[] TokenlenHiLo = { 0x64, (byte)len, (byte)(len >> 8) };
            //buf[0] = (byte)len;
            //buf[1] = (byte)(len >> 8);
            buf = br.ReadBytes(len);  //read full file to array
            br.Close();

            serialPort1.Write(TokenlenHiLo, 0, 3);  //Send Length

            serialPort1.Write(buf, 0, len); //Send file to USB

            //while (len-- > 0)
            //{
            //    buf = br.ReadBytes(1);  
            //    serialPort1.Write(buf, 0, 4);
            //}

            WriteToOutput("Finished", Color.Black);
            //timer1.Enabled = true;
        }

        /********************************  Stand Alone Functions *****************************************/
        private void WriteToOutput(string strMsg, Color color)
        {
            rtbOutput.SelectionColor = color;
            rtbOutput.AppendText(strMsg + "\r");
            rtbOutput.ScrollToCaret();
        }

    }
}


