import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minesweeper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Container(color: Colors.red, child: const Gamepage()),
    );
  }
}

/// 扫雷游戏主界面
class Gamepage extends StatefulWidget {
  const Gamepage({super.key});

  @override
  State<Gamepage> createState() => _GamepageState();
}

/// 游戏状态管理类
class _GamepageState extends State<Gamepage> {
  static const int boardSize = 10; // 棋盘大小
  static const int mineCount = 10; // 地雷数量

  late GameState currentGameState;

  late GameAgent gameAgent;

  @override
  void initState() {
    super.initState();
    gameAgent = GameAgent(boardSize, mineCount);
    resetGameState();
  }

  void resetGameState() {
    setState(() {
      currentGameState = gameAgent.initializeGame();
    });
  }

  void revealCell(int row, int col) {
    if (currentGameState.gameOver ||
        currentGameState.revealed[row][col] ||
        currentGameState.flagged[row][col]) return;

    setState(() {
      final result = gameAgent.revealCell(row, col);
      currentGameState = result;
    });
  }

  void toggleFlag(int row, int col) {
    if (currentGameState.gameOver || currentGameState.revealed[row][col])
      return;

    setState(() {
      final result = gameAgent.toggleFlag(row, col);
      currentGameState = result;
    });
  }

  Color getNumberColor(int number) {
    return Colors.primaries[number % Colors.primaries.length];
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('扫雷游戏规则'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('基本规则：', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• 游戏在10x10的棋盘上进行'),
              Text('• 棋盘上随机分布着10个地雷'),
              Text('• 目标是找出所有非地雷的格子'),
              SizedBox(height: 10),
              Text('格子类型：', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• 空白格子：点击后自动展开周围格子'),
              Text('• 数字格子：显示周围地雷数量'),
              Text('• 地雷格子：点击到则游戏结束'),
              SizedBox(height: 10),
              Text('操作方式：', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• 左键点击：揭示格子'),
              Text('• 右键点击：标记/取消标记地雷'),
              Text('• 第一次点击保证安全'),
              SizedBox(height: 10),
              Text('游戏状态：', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• 进行中：继续揭示格子'),
              Text('• 失败：点击到地雷'),
              Text('• 胜利：成功标记所有非地雷格子'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('明白了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minesweeper'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 添加规则按钮
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showRules,
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 游戏状态显示
          if (currentGameState.gameOver || currentGameState.gameWon)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                currentGameState.gameOver ? 'Game Over!' : 'You Won!',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          // 游戏棋盘
          Expanded(
            child: Center(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: boardSize,
                ),
                itemCount: boardSize * boardSize,
                itemBuilder: (context, index) {
                  int row = index ~/ boardSize;
                  int col = index % boardSize;
                  return GestureDetector(
                    onTap: () => revealCell(row, col),
                    onSecondaryTap: () => toggleFlag(row, col),
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: currentGameState.revealed[row][col]
                            ? (currentGameState.mines[row][col]
                                ? Colors.red
                                : Colors.white)
                            : Colors.grey[300],
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Center(
                        child: currentGameState.revealed[row][col]
                            ? (currentGameState.mines[row][col]
                                ? const Icon(Icons.warning, color: Colors.black)
                                : currentGameState.numbers[row][col] > 0
                                    ? Text(
                                        '${currentGameState.numbers[row][col]}',
                                        style: TextStyle(
                                          color: getNumberColor(currentGameState
                                              .numbers[row][col]),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null)
                            : currentGameState.flagged[row][col]
                                ? const Icon(Icons.flag, color: Colors.red)
                                : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // 新游戏按钮
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: resetGameState,
              child: const Text('New Game'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 游戏状态Model
class GameState {
  List<List<bool>> mines;
  List<List<int>> numbers;
  List<List<bool>> revealed;
  List<List<bool>> flagged;
  bool gameOver;
  bool gameWon;
  bool isFirstClick;

  GameState({
    required this.mines,
    required this.numbers,
    required this.revealed,
    required this.flagged,
    this.gameOver = false,
    this.gameWon = false,
    this.isFirstClick = true,
  });
}

/// 游戏代理类 规则引擎
class GameAgent {
  final int boardSize;
  final int mineCount;
  late List<List<bool>> mines;
  late List<List<int>> numbers;
  late List<List<bool>> revealed;
  late List<List<bool>> flagged;
  bool gameOver = false;
  bool gameWon = false;
  bool isFirstClick = true;

  GameAgent(this.boardSize, this.mineCount);

  GameState initializeGame() {
    // 初始化空棋盘
    mines = List.generate(boardSize, (_) => List.filled(boardSize, false));
    numbers = List.generate(boardSize, (_) => List.filled(boardSize, 0));
    revealed = List.generate(boardSize, (_) => List.filled(boardSize, false));
    flagged = List.generate(boardSize, (_) => List.filled(boardSize, false));
    gameOver = false;
    gameWon = false;
    isFirstClick = true;

    // 随机放置地雷
    _placeMines();

    // 计算数字
    _calculateNumbers();

    return GameState(
      mines: mines,
      numbers: numbers,
      revealed: revealed,
      flagged: flagged,
      isFirstClick: isFirstClick,
    );
  }

  /// 放置地雷
  void _placeMines() {
    final random = Random();
    int minesPlaced = 0;
    while (minesPlaced < mineCount) {
      int row = random.nextInt(boardSize);
      int col = random.nextInt(boardSize);
      if (!mines[row][col]) {
        mines[row][col] = true;
        minesPlaced++;
      }
    }
  }

  /// 计算每个格子周围的地雷数
  void _calculateNumbers() {
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (!mines[i][j]) {
          numbers[i][j] = _countAdjacentMines(i, j);
        }
      }
    }
  }

  /// 计算指定位置周围的地雷数
  int _countAdjacentMines(int row, int col) {
    int count = 0;
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        int newRow = row + i;
        int newCol = col + j;
        if (newRow >= 0 &&
            newRow < boardSize &&
            newCol >= 0 &&
            newCol < boardSize &&
            mines[newRow][newCol]) {
          count++;
        }
      }
    }
    return count;
  }

  /// 处理格子点击
  GameState revealCell(int row, int col) {
    if (gameOver || revealed[row][col] || flagged[row][col]) {
      return GameState(
        mines: mines,
        numbers: numbers,
        revealed: revealed,
        flagged: flagged,
        gameOver: gameOver,
        gameWon: gameWon,
        isFirstClick: isFirstClick,
      );
    }

    // 第一次点击保护
    if (isFirstClick) {
      _ensureSafeFirstClick(row, col);
      isFirstClick = false;
    }

    revealed[row][col] = true;

    if (mines[row][col]) {
      gameOver = true;
      _revealAllMines();
    } else if (numbers[row][col] == 0) {
      _revealAdjacentCells(row, col);
    }

    _checkWinCondition();

    return GameState(
      mines: mines,
      numbers: numbers,
      revealed: revealed,
      flagged: flagged,
      gameOver: gameOver,
      gameWon: gameWon,
      isFirstClick: isFirstClick,
    );
  }

  /// 处理右键标记
  GameState toggleFlag(int row, int col) {
    if (gameOver || revealed[row][col]) {
      return GameState(
        mines: mines,
        numbers: numbers,
        revealed: revealed,
        flagged: flagged,
        gameOver: gameOver,
        gameWon: gameWon,
        isFirstClick: isFirstClick,
      );
    }

    flagged[row][col] = !flagged[row][col];
    _checkWinCondition();

    return GameState(
      mines: mines,
      numbers: numbers,
      revealed: revealed,
      flagged: flagged,
      gameOver: gameOver,
      gameWon: gameWon,
      isFirstClick: isFirstClick,
    );
  }

  /// 确保第一次点击安全
  void _ensureSafeFirstClick(int row, int col) {
    // 如果第一次点击到地雷，重新放置地雷
    if (mines[row][col]) {
      mines[row][col] = false;
      // 在随机位置放置新的地雷
      final random = Random();
      while (true) {
        int newRow = random.nextInt(boardSize);
        int newCol = random.nextInt(boardSize);
        if (!mines[newRow][newCol] && (newRow != row || newCol != col)) {
          mines[newRow][newCol] = true;
          break;
        }
      }
      // 重新计算数字
      _calculateNumbers();
    }
  }

  /// 揭示所有地雷
  void _revealAllMines() {
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (mines[i][j]) revealed[i][j] = true;
      }
    }
  }

  /// 自动展开空白格子
  /// 使用广度优先搜索(BFS)来展开空白区域
  void _revealAdjacentCells(int row, int col) {
    // 使用队列来存储待处理的格子
    final queue = <Point<int>>[];
    // 使用集合来记录已处理的格子，避免重复处理
    final processed = <Point<int>>{};

    // 将起始点加入队列
    queue.add(Point(row, col));
    processed.add(Point(row, col));

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentRow = current.x;
      final currentCol = current.y;

      // 如果当前格子是数字，只揭示它自己
      if (numbers[currentRow][currentCol] > 0) {
        revealed[currentRow][currentCol] = true;
        continue;
      }

      // 揭示当前格子
      revealed[currentRow][currentCol] = true;

      // 检查周围的8个格子
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          // 跳过中心格子
          if (i == 0 && j == 0) continue;

          final newRow = currentRow + i;
          final newCol = currentCol + j;
          final newPoint = Point(newRow, newCol);

          // 检查边界和是否已处理
          if (newRow >= 0 &&
              newRow < boardSize &&
              newCol >= 0 &&
              newCol < boardSize &&
              !processed.contains(newPoint) &&
              !revealed[newRow][newCol] &&
              !flagged[newRow][newCol]) {
            // 如果是空白格子，加入队列继续处理
            if (numbers[newRow][newCol] == 0) {
              queue.add(newPoint);
            } else {
              // 如果是数字格子，直接揭示
              revealed[newRow][newCol] = true;
            }
            processed.add(newPoint);
          }
        }
      }
    }
  }

  /// 检查坐标是否在棋盘范围内
  bool _isValidPosition(int row, int col) {
    return row >= 0 && row < boardSize && col >= 0 && col < boardSize;
  }

  /// 获取周围8个格子的坐标
  List<Point<int>> _getAdjacentPositions(int row, int col) {
    final positions = <Point<int>>[];
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        final newRow = row + i;
        final newCol = col + j;
        if (_isValidPosition(newRow, newCol)) {
          positions.add(Point(newRow, newCol));
        }
      }
    }
    return positions;
  }

  /// 检查是否获胜
  void _checkWinCondition() {
    bool allNonMinesRevealed = true;
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (!mines[i][j] && !revealed[i][j]) {
          allNonMinesRevealed = false;
          break;
        }
      }
    }
    if (allNonMinesRevealed) {
      gameWon = true;
    }
  }
}
