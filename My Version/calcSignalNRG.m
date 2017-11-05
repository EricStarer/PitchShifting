function NRG = calcSignalNRG(x)
%this function takes x and calculates its energy, works on row and column
%vectors

NRG = sum(x.^2);
