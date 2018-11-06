unit lvl2DData;

interface

type
  InvalidLVLFile=class(Exception)
    
    constructor(text: string) :=
    inherited Create(text);
    
  end;
  
  TileT=(EmptyTile, WallTile);
  lvl2D=class
    
    public tls: array[,] of TileT;
    
    
    
    public constructor(fname: string);
    
  end;

implementation

constructor lvl2D.Create(fname: string);
begin
  var lns := ReadAllLines(fname);
  
  if lns.Length = 0 then raise new InvalidLVLFile('File can''t be empty');
  if lns.Skip(1).Any(s->s.Length<>lns[0].Length) then
    raise new InvalidLVLFile('Lines must have the same length');
  if lns[0].Length = 0 then raise new InvalidLVLFile('File can''t be empty');
  
  tls := new TileT[lns[0].Length, lns.Length];
  for var x := 0 to lns[0].Length-1 do
    for var y := 0 to lns.Length-1 do
    case lns[y][x+1] of
      
      '-': tls[x,y] := EmptyTile;
      'x': tls[x,y] := WallTile;
      
      else raise new InvalidLVLFile($'Invalid char [> {lns[y][x+1]} <]');
    end;
  
end;



end.