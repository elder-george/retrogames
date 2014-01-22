using System;
using System.Text;
using System.IO;

class Wav2Asm{

    static void Main(string[] args){
        try{
            var bytes = File.ReadAllBytes(args[0]);
            var signature = Encoding.ASCII.GetBytes("data");
            var start = 0;
            ushort length = 0;
            for(var i = 0; i < bytes.Length; i++){
                if (bytes[i] == signature[0] && bytes[i+1] == signature[1]
                    && bytes[i+2] == signature[2] && bytes[i] == signature[0]){
                    start = i;
                    length = (ushort)BitConverter.ToUInt32(bytes, i + 4);
                    break;
                }
            }
            if (start > 0 && length > 0){
                Console.WriteLine("global " + args[0].Replace(".", "_"));
                Console.WriteLine("section .data");
                Console.WriteLine(args[0].Replace(".", "_")+":");
                Console.WriteLine("dw {0}", length);
                for (var i = 0; i < length / 24; i++){
                    if (length - i * 24 > 0){
                        Console.Write("db ");
                        for (var j = 0; j < 24; j++){
                            if (i * 24  + j >= length){
                                break;
                            }
                            if (j > 0){
                                Console.Write(", ");
                            }
                            Console.Write("0{0:X}h", bytes[i*24 + j]);
                        }
                        Console.WriteLine();
                    }
                }
            }
        }catch(Exception e){
            Console.WriteLine(e);
        }
    }
}