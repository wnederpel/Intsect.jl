## TODO

so we can do some moves and place some pieces, I think the next step is to 
look at how the engine should interact and behave according to the UHP.
There probably should be some validation on the actions that are generated, 
and then we can show the errors in the correct format, throwing an error to
exit the entire function call stack back to main in probably best, 
then catch in main() and log the message. 

Also look at the desired error handling by the UPH

## What do the engines have to do?

https://github.com/jonthysell/Mzinga/wiki/UniversalHiveProtocol#engine-commands

command:
info
status:
done

command:
newgame
status:
done for MLP

command:
play
status:
climb left to do

command:
pass
status:
done

command:
validmoves
status:
done

command:
bestmove
status:
-

command:
undo
status:
-

command:
options
status:
-


