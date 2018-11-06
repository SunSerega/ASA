unit SnakeData;

interface

uses lvl2DData;

type
  SnakeLvl=class;
  Position = record
    
    public X,Y: integer;
    
    public constructor(X,Y: integer);
    begin
      self.X := X;
      self.Y := Y;
    end;
    
    public static function operator=(p1,p2:Position): boolean :=
    (p1.X=p2.X) and (p1.Y=p2.Y);
    
    public static function operator<>(p1,p2:Position): boolean :=
    not (p1=p2);
    
  end;
  
  Snake=class
    
    public lvl: SnakeLvl;
    public drct: byte;
    private last_drct: byte;
    public growing := false;
    public tail: LinkedList<Position>;
    public Color := System.ConsoleColor.Red;
    
    private procedure Init(lvl: SnakeLvl; drct: byte; tail: sequence of Position);
    
    public constructor(lvl: SnakeLvl);
    
    public constructor(lvl: SnakeLvl; drct: byte; tail: sequence of Position) :=
    Init(lvl, drct, tail);
    
    public procedure Move;
    
    public procedure ChangeDrct(ndrct: byte);
    
  end;
  
  SnakeLvl=class(lvl2D)
    
    public snakes := new List<Snake>;
    public food := new List<Position>;
    
    public constructor(fname: string; fc: integer);
    
    public procedure RestoreFood;
    
  end;

implementation

procedure Snake.Init(lvl: SnakeLvl; drct: byte; tail: sequence of Position);
begin
  self.lvl := lvl;
  lvl.snakes += self;
  self.drct := drct;
  self.last_drct := drct;
  self.tail := new LinkedList<Position>(tail);
end;

constructor Snake.Create(lvl: SnakeLvl);
begin
  
  var p := new Position((lvl.tls.GetLength(0)-1) div 2, Max(4, (lvl.tls.GetLength(1)-1) div 3));
  var tail :=
    p.Y.Downto(p.Y-4)
    .Select(y->new Position(p.X, y));
  
  Init(lvl, 0, tail);
end;

procedure Snake.Move;
begin
  last_drct := drct;
  
  var nh := tail.First.Value;
  case drct and $3 of
    0: nh.Y += 1;
    1: nh.X -= 1;
    2: nh.Y -= 1;
    3: nh.X += 1;
  end;
  var w := lvl.tls.GetLength(0);
  var h := lvl.tls.GetLength(1);
  nh.X := (nh.X + w) mod w;
  nh.Y := (nh.Y + h) mod h;
  
  tail.AddFirst(nh);
  if growing then
    growing := false else
    tail.RemoveLast;
  
end;

procedure Snake.ChangeDrct(ndrct: byte) :=
if (4+last_drct-ndrct) and $3 <> 2 then
  drct := ndrct;

constructor SnakeLvl.Create(fname: string; fc: integer);
begin
  inherited Create(fname);
  food.Capacity := fc;
end;

procedure SnakeLvl.RestoreFood :=
if food.Count<>food.Capacity then
begin
  var nf := new Position(Random(tls.GetLength(0)),Random(tls.GetLength(1)));
  if tls[nf.X, nf.Y] <> TileT.EmptyTile then exit;
  if food.Contains(nf) then exit;
  if snakes.SelectMany(snk->snk.tail).Any(t->t=nf) then exit;
  food.Add(nf);
end;

end.