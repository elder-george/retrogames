using System;
using System.IO;
using System.Linq;
using System.Drawing;
using System.Drawing.Imaging;


class SpriteBuilder{
    static void Main(string[] args){
        try{
            var spriteNames = args.Select(arg => Path.GetFileNameWithoutExtension(arg)+"Sprite");
            foreach(var spriteName in spriteNames){
                Console.WriteLine("global " +spriteName);
            }
            Console.WriteLine("section .data");
            foreach(var arg in args){
                var img = new Bitmap(arg);
                var width = img.Width;
                if (width % 8 != 0){
                    throw new InvalidOperationException("Image width must be divideable by 8");
                }
                var height = img.Height;
                var spriteName = Path.GetFileNameWithoutExtension(arg)+"Sprite";
                Console.WriteLine(spriteName + ":");
                Console.WriteLine("db {0}, {1}", width / 8, height);
                for (var i = 0; i < height; i++)
                {
                    Console.Write(width % 32 == 0 
                                    ? "dd " 
                                    : width % 16 == 0 
                                        ? "dw " : "db ");
                    for (var j = 0; j < width; j++){
                        var pixel = img.GetPixel(j, i);
                        Console.Write(pixel.R == 0 ? 1: 0);
                        if (j != 0 && (j % 32 == 31 || j == width - 1))
                            Console.Write("b ");
                    }            
                    Console.WriteLine();
                }
            }
         } catch(Exception e){
            Console.Error.WriteLine(e);
         }
    }
}