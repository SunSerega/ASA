uses SnakeData;
uses lvl2DData;

{ $define SkipConsole}

const
  fill0 = #9608;
  fill1 = #9619;
  fill2 = #9618;
  fill3 = #9617;
  fill4 = ' ';

var
  LastDrawing: array[,] of (char, System.ConsoleColor);
  pl: Snake;
  pl_contol: System.Threading.Thread;
  max_l := 10;

procedure DrawLvlBorder(lvl: SnakeLvl);
begin
  var w := lvl.tls.GetLength(0);
  var h := lvl.tls.GetLength(1);
  
  LastDrawing := new System.Tuple<char, System.ConsoleColor>[w+2,h+2];
  
  {$ifndef SkipConsole}
  System.Console.ForegroundColor := System.ConsoleColor.DarkCyan;
  System.Console.SetCursorPosition(0,0);
  {$endif}
  
  System.Console.Write(fill0*(w+2)+#10);
  for var y := 0 to h-1 do
    System.Console.Write(fill0+fill4*w+fill0+#10);
  System.Console.Write(fill0*(w+2));
end;

procedure TryDrawPxl(x,y: integer; ch: char; c: System.ConsoleColor := System.ConsoleColor.Gray);
begin
  var t := LastDrawing[x,y];
  if (t = nil) or (t[0] <> ch) or (t[1] <> c) then
  begin
    {$ifndef SkipConsole}
    System.Console.SetCursorPosition(x, y);
    System.Console.ForegroundColor := c;
    {$endif}
    System.Console.Write(ch);
    LastDrawing[x,y] := (ch, c);
  end;
end;

procedure Draw(lvl: SnakeLvl);
begin
  var w := lvl.tls.GetLength(0);
  var h := lvl.tls.GetLength(1);
  
  var sps := new Dictionary<Position, (char, System.ConsoleColor)>;
  
  foreach var f in lvl.food do
    sps[f] := (fill0, System.ConsoleColor.Blue);
  
  foreach var snk in lvl.snakes do
  begin
    foreach var p in snk.tail.Skip(1) do
      sps[p] := (fill2, snk.Color);
    
    sps[snk.tail.First.Value] := (fill0, snk.Color);
  end;
  
  for var y := 0 to h-1 do
    for var x := 0 to w-1 do
    begin
      var val: (char, System.ConsoleColor);
      if sps.TryGetValue(new Position(x,y), val) then
        TryDrawPxl(x+1, y+1, val[0], val[1]) else
      case lvl.tls[x,y] of
        EmptyTile:  TryDrawPxl(x+1, y+1, fill4);
        WallTile:   TryDrawPxl(x+1, y+1, fill0);
      end;
    end;
  
  System.Console.ForegroundColor := System.ConsoleColor.Gray;
  System.Console.SetCursorPosition(w+2,0);
  System.Console.Write($'{pl.tail.Count,4}/{max_l}');
  
end;

function TryPlay(lvl: SnakeLvl): boolean;
begin
  DrawLvlBorder(lvl);
  pl := new Snake(lvl);
  pl_contol.Resume;
  pl.Color := System.ConsoleColor.DarkGreen;
  
  while true do
  begin
    Draw(lvl);
    
    foreach var snk in lvl.snakes.ToList do
    begin
      if snk<>pl then snk.ChangeDrct(Random(4));
      snk.Move;
      var h := snk.tail.First.Value;
      if lvl.food.Contains(h) then
      begin
        lvl.food.Remove(h);
        snk.growing := true;
      end else
      if lvl.tls[h.X,h.Y] <> TileT.EmptyTile then
      begin
        if snk=pl then exit;
        snk.tail := nil;
        lvl.snakes.Remove(snk);
      end;
    end;
    
    foreach var snk1 in lvl.snakes.ToList do
      foreach var snk2 in lvl.snakes.ToList do
        if (snk1.tail <> nil) and (snk2.tail <> nil) then
          if (snk1 <> snk2) and (snk1.tail.First.Value=snk2.tail.First.Value) then
            foreach var snk in Seq(snk1,snk2) do
            begin
              if snk=pl then exit;
              snk.tail := nil;
              lvl.snakes.Remove(snk);
            end else
          begin
            var h := snk1.tail.First.Value;
            var ind := snk2.tail.Skip(1).Numerate.FirstOrDefault(t->t[1]=h)?.Item1;
            
            if (ind<>nil) then
              if ind=1 then
              begin
                
                loop 2 do snk2.tail.RemoveFirst;
                if snk2.tail.Count<2 then
                begin
                  if snk2=pl then exit;
                  snk2.tail := nil;
                  lvl.snakes.Remove(snk2);
                end;
                
              end else
              begin
                
                var bp := snk2.tail.First;
                loop ind.Value do bp := bp.Next;
                if bp.Next <> nil then
                begin
                  
                  var drct: byte;
                  case bp.Next.Value.X-bp.Value.X of
                    -1: drct := 1;
                    +1: drct := 3;
                    else case bp.Next.Value.X-bp.Value.X of
                      -1: drct := 2;
                      +1: drct := 0;
                    end;
                  end;
                  
                  var snk := new Snake(lvl,drct,snk2.tail.Skip(ind.Value+1));
                  
                  if snk.tail.Count<2 then
                  begin
                    snk.tail := nil;
                    lvl.snakes.Remove(snk);
                  end;
                  
                end;
                
                while snk2.tail.Last <> bp do
                  snk2.tail.RemoveLast;
                snk2.tail.RemoveLast;
                
              end;
          end;
    
    if pl.tail.Count = max_l then
    begin
      Result := true;
      exit;
    end;
    
    lvl.RestoreFood;
    Sleep(200);
  end;
end;

function GetKeyState(nVirtKey: byte): byte;
external 'User32.dll' name 'GetKeyState';

function KeyPr(kk: byte) :=
GetKeyState(kk) shr 7 = $01;

begin
  try
    {$ifndef SkipConsole}
    System.Console.CursorVisible := false;
    {$endif}
    
    pl_contol := System.Threading.Thread.Create(()->
    try
      while pl = nil do Sleep(10);
      
      while true do
      begin
        
        if KeyPr($53) or KeyPr($28) then pl.ChangeDrct(0);
        if KeyPr($41) or KeyPr($25) then pl.ChangeDrct(1);
        if KeyPr($57) or KeyPr($26) then pl.ChangeDrct(2);
        if KeyPr($44) or KeyPr($27) then pl.ChangeDrct(3);
        
        Sleep(10);
      end;
    except
      on e: Exception do
      begin
        WriteAllText('error.log', _ObjectToString(e));
        halt;
      end;
    end);
    pl_contol.Start;
    pl_contol.Suspend;
    
    foreach var lvl_name in
      System.IO.Directory.EnumerateFiles('GD')
      .Where(fname->fname.StartsWith('GD\std lvl'))
      .Sorted
      .Cycle
    do
    begin
      var lvl := new SnakeLvl(lvl_name,5);
      
      while not TryPlay(lvl) do
      begin
        pl_contol.Suspend;
        System.Console.Clear;
        writeln('GameOver!');
        writeln('Press Enter to restart');
        writeln('Press Esc to exit');
        while true do
        begin
          var key := System.Console.ReadKey(true);
          if key.Key=System.ConsoleKey.Enter then break;
          if key.Key=System.ConsoleKey.Escape then Halt;
        end;
        lvl := new SnakeLvl(lvl_name,5);
      end;
      pl_contol.Suspend;
    end;
    
  except
    on e: Exception do
    begin
      WriteAllText('error.log', _ObjectToString(e));
      halt;
    end;
  end;
end.