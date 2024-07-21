import 'package:flutter/material.dart';
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter_test/flutter_test.dart';
import 'package:chessground/chessground.dart';

const boardSize = 200.0;
const squareSize = boardSize / 8;

void main() {
  group('BoardEditor', () {
    testWidgets('empty board has no pieces', (WidgetTester tester) async {
      await tester.pumpWidget(buildBoard(pieces: {}));
      expect(find.byType(BoardEditor), findsOneWidget);
      expect(find.byType(PieceWidget), findsNothing);

      for (final square in allSquares) {
        expect(find.byKey(Key('$square-empty')), findsOneWidget);
      }
    });

    testWidgets('displays pieces on the correct squares',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildBoard(
          pieces: {
            const SquareId('a1'): Piece.whiteKing,
            const SquareId('b2'): Piece.whiteQueen,
            const SquareId('c3'): Piece.whiteRook,
            const SquareId('d4'): Piece.whiteBishop,
            const SquareId('e5'): Piece.whiteKnight,
            const SquareId('f6'): Piece.whitePawn,
            const SquareId('a2'): Piece.blackKing,
            const SquareId('a3'): Piece.blackQueen,
            const SquareId('a4'): Piece.blackRook,
            const SquareId('a5'): Piece.blackBishop,
            const SquareId('a6'): Piece.blackKnight,
            const SquareId('a7'): Piece.blackPawn,
          },
        ),
      );
      expect(find.byKey(const Key('a1-whiteKing')), findsOneWidget);
      expect(find.byKey(const Key('b2-whiteQueen')), findsOneWidget);
      expect(find.byKey(const Key('c3-whiteRook')), findsOneWidget);
      expect(find.byKey(const Key('d4-whiteBishop')), findsOneWidget);
      expect(find.byKey(const Key('e5-whiteKnight')), findsOneWidget);
      expect(find.byKey(const Key('f6-whitePawn')), findsOneWidget);

      expect(find.byKey(const Key('a2-blackKing')), findsOneWidget);
      expect(find.byKey(const Key('a3-blackQueen')), findsOneWidget);
      expect(find.byKey(const Key('a4-blackRook')), findsOneWidget);
      expect(find.byKey(const Key('a5-blackBishop')), findsOneWidget);
      expect(find.byKey(const Key('a6-blackKnight')), findsOneWidget);
      expect(find.byKey(const Key('a7-blackPawn')), findsOneWidget);

      expect(find.byType(PieceWidget), findsNWidgets(12));
    });

    testWidgets('tapping a square triggers the onTappedSquare callback',
        (WidgetTester tester) async {
      for (final orientation in Side.values) {
        SquareId? tappedSquare;
        await tester.pumpWidget(
          buildBoard(
            pieces: {},
            onTappedSquare: (square) => tappedSquare = square,
            orientation: orientation,
          ),
        );

        await tester.tapAt(
          squareOffset(const SquareId('a1'), orientation: orientation),
        );
        expect(tappedSquare, 'a1');

        await tester.tapAt(
          squareOffset(const SquareId('g8'), orientation: orientation),
        );
        expect(tappedSquare, 'g8');
      }
    });

    testWidgets('dragging pieces to a new square calls onDroppedPiece',
        (WidgetTester tester) async {
      (SquareId? origin, SquareId? destination, Piece? piece) callbackParams =
          (null, null, null);

      await tester.pumpWidget(
        buildBoard(
          pieces: readFen(dc.kInitialFEN),
          onDroppedPiece: (o, d, p) => callbackParams = (o, d, p),
        ),
      );

      // Drag an empty square => nothing happens
      await tester.dragFrom(
        squareOffset(const SquareId('e4')),
        const Offset(0, -(squareSize * 2)),
      );
      await tester.pumpAndSettle();
      expect(callbackParams, (null, null, null));

      // Play e2-e4 (legal move)
      await tester.dragFrom(
        squareOffset(const SquareId('e2')),
        const Offset(0, -(squareSize * 2)),
      );
      await tester.pumpAndSettle();
      expect(callbackParams, ('e2', 'e4', Piece.whitePawn));

      // Capture our own piece (illegal move)
      await tester.dragFrom(
        squareOffset(const SquareId('a1')),
        const Offset(squareSize, 0),
      );
      expect(callbackParams, ('a1', 'b1', Piece.whiteRook));
    });

    testWidgets('dragging a piece onto the board calls onDroppedPiece',
        (WidgetTester tester) async {
      (SquareId? origin, SquareId? destination, Piece? piece) callbackParams =
          (null, null, null);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              BoardEditor(
                size: boardSize,
                orientation: Side.white,
                pieces: const {},
                onDroppedPiece: (o, d, p) {
                  callbackParams = (o, d, p);
                },
              ),
              Draggable(
                key: const Key('new piece'),
                hitTestBehavior: HitTestBehavior.translucent,
                data: Piece.whitePawn,
                feedback: const SizedBox.shrink(),
                child: PieceWidget(
                  piece: Piece.whitePawn,
                  size: squareSize,
                  pieceAssets: PieceSet.merida.assets,
                ),
              ),
            ],
          ),
        ),
      );

      final pieceDraggable = find.byKey(const Key('new piece'));
      final pieceCenter = tester.getCenter(pieceDraggable);

      final newSquareCenter =
          tester.getCenter(find.byKey(const Key('e2-empty')));

      await tester.drag(
        pieceDraggable,
        newSquareCenter - pieceCenter,
      );
      expect(callbackParams, (null, 'e2', Piece.whitePawn));
    });

    testWidgets('dragging a piece off the board calls onDiscardedPiece',
        (WidgetTester tester) async {
      SquareId? discardedSquare;
      await tester.pumpWidget(
        buildBoard(
          pieces: readFen(dc.kInitialFEN),
          onDiscardedPiece: (square) => discardedSquare = square,
        ),
      );

      await tester.dragFrom(
        squareOffset(const SquareId('e1')),
        const Offset(0, squareSize),
      );
      await tester.pumpAndSettle();
      expect(discardedSquare, 'e1');
    });
  });
}

Widget buildBoard({
  required Pieces pieces,
  Side orientation = Side.white,
  void Function(SquareId square)? onTappedSquare,
  void Function(SquareId? origin, SquareId destination, Piece piece)?
      onDroppedPiece,
  void Function(SquareId square)? onDiscardedPiece,
}) {
  return MaterialApp(
    home: BoardEditor(
      size: boardSize,
      orientation: orientation,
      pieces: pieces,
      onTappedSquare: onTappedSquare,
      onDiscardedPiece: onDiscardedPiece,
      onDroppedPiece: onDroppedPiece,
    ),
  );
}

Offset squareOffset(SquareId id, {Side orientation = Side.white}) {
  final o = id.coord.offset(orientation, squareSize);
  return Offset(o.dx + squareSize / 2, o.dy + squareSize / 2);
}
