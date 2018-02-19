/*
 * 2048
 *
 * Join the numbers and get to the 2048 tile.
 *
 * Commands:
 *
 *   Use the arrow keys to move the tiles.
 *   When two tiles with the same number touch, they merge into one.
 *
 *   w, s, a, d - Alternate keys (up, down, left, right)
 *   CTRL-E, CTRL-X, CTRL-S, CTRL-D - Wordstar-compatible control keys
 *
 * Compile:
 *
 *   zcc +cpm -o=2048.com cpm2048.c
 *
 * Credits:
 *
 *   Based on 2048 created by Gabriele Cirulli.
 *   Source code from console version for GNU/Linux by Maurits van der Schee
 *   adapted to CP/M by Marco Maccaferri <macca@maccasoft.com>
 */

#pragma output noprotectmsdos
#pragma output noredir
#pragma output nogfxglobals

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>

#define CTRL_A  1
#define CTRL_B  2
#define CTRL_C  3
#define CTRL_D  4
#define CTRL_E  5
#define CTRL_F  6
#define CTRL_G  7
#define CTRL_H  8
#define CTRL_I  9
#define CTRL_J  10
#define CTRL_K  11
#define CTRL_L  12
#define CTRL_M  13
#define CTRL_N  14
#define CTRL_O  15
#define CTRL_P  16
#define CTRL_Q  17
#define CTRL_R  18
#define CTRL_S  19
#define CTRL_T  20
#define CTRL_U  21
#define CTRL_V  22
#define CTRL_W  23
#define CTRL_X  24
#define CTRL_Y  25
#define CTRL_Z  26
#define ESC     27

#define BLACK   0
#define RED     1
#define GREEN   2
#define YELLOW  3
#define BLUE    4
#define MAGENTA 5
#define CYAN    6
#define WHITE   7

#ifndef true
#define true    1
#endif

#ifndef false
#define false   0
#endif

#ifndef getch
#define getch getchar
#endif

#define SIZE    4
#define BOARD_X 25
#define BOARD_Y 4

unsigned int score = 0;
uint8_t scheme = 0;
uint8_t board[SIZE][SIZE];

const char * labels[] = {
    "   \371   ",
    "   2   ",
    "   4   ",
    "   8   ",
    "   16  ",
    "   32  ",
    "   64  ",
    "  128  ",
    "  256  ",
    "  512  ",
    " 1024  ",
    " 2048  ",
    " 4096  ",
    " 8192  ",
};

uint8_t colors[] = {
    BLACK,   WHITE, // 0
    BLUE,    WHITE, // 2
    CYAN,    WHITE, // 4
    GREEN,   WHITE, // 8
    YELLOW,  BLACK, // 16
    MAGENTA, WHITE, // 32
    RED,     WHITE, // 64
    WHITE,   BLACK, // 128
    BLUE,    WHITE, // 256
    CYAN,    WHITE, // 512
    GREEN,   WHITE, // 1024
    YELLOW,  BLACK, // 2048
    MAGENTA, WHITE, // 4096
    RED,     WHITE, // 8192
};

void getColor(uint8_t value, char * color, size_t length) {
    uint8_t * background = colors + 0;
    uint8_t * foreground = colors + 1;

    if (value > 0)
        while (value--) {
            if (background + 2 < colors + sizeof(colors)) {
                background += 2;
                foreground += 2;
            }
        }
    snprintf(color, length, "\033[38;5;%d;48;5;%dm", *foreground, *background);
}

void drawBorder() {
    uint8_t x, y, cy;
    
    cy = BOARD_Y + 1;
    printf("\033[%d;%dH\334", cy++, BOARD_X - 1);
    for (x = 0; x < SIZE; x++) {
        printf("\334\334\334\334\334\334\334");
    }
    printf("\334");
    for (y = 0; y < SIZE; y++) {
        printf("\033[%d;%dH\333\033[28C\333", cy++, BOARD_X - 1);
        printf("\033[%d;%dH\333\033[28C\333", cy++, BOARD_X - 1);
        printf("\033[%d;%dH\333\033[28C\333", cy++, BOARD_X - 1);
    }
    printf("\033[%d;%dH\337", cy++, BOARD_X - 1);
    for (x = 0; x < SIZE; x++) {
        printf("\337\337\337\337\337\337\337");
    }
    printf("\337");
}

void drawBoard() {
    uint8_t x, y, cy;
    char c;
    char color[40];

    cy = BOARD_Y;
    printf("\033[%d;%dHcpm2048.c %14d pts\n\n", cy, BOARD_X, score);
    cy += 2;

    for (y = 0; y < SIZE; y++) {
        printf("\033[%d;%dH", cy++, BOARD_X);
        for (x = 0; x < SIZE; x++) {
            getColor(board[x][y], color, 40);
            printf("%s       ", color);
        }
        printf("\033[%d;%dH", cy++, BOARD_X);
        for (x = 0; x < SIZE; x++) {
            getColor(board[x][y], color, 40);
            printf("%s%s", color, labels[board[x][y]]);
        }
        printf("\033[%d;%dH", cy++, BOARD_X);
        for (x = 0; x < SIZE; x++) {
            getColor(board[x][y], color, 40);
            printf("%s       ", color);
        }
    }
    cy++;

    printf("\033[%d;1H\033[m\n", cy);
    printf("\033[%d;%dH        \021,\036,\020,\037 or q        ", cy, BOARD_X);
    printf("\033[%d;%dH", cy, BOARD_X);
}

uint8_t findTarget(uint8_t x, uint8_t y, uint8_t stop) {
    uint8_t t;
    // if the position is already on the first, don't evaluate
    if (y == 0) {
        return y;
    }
    for (t = y - 1; t >= 0; t--) {
        if (board[x][t] != 0) {
            if (board[x][t] != board[x][y]) {
                // merge is not possible, take next position
                return t + 1;
            }
            return t;
        }
        else {
            // we should not slide further, return this one
            if (t == stop) {
                return t;
            }
        }
    }
    // we did not find a
    return y;
}

bool slideArray(uint8_t x) {
    bool success = false;
    uint8_t y, t, stop = 0;

    for (y = 0; y < SIZE; y++) {
        if (board[x][y] != 0) {
            t = findTarget(x, y, stop);
            // if target is not original position, then move or merge
            if (t != y) {
                // if target is zero, this is a move
                if (board[x][t] == 0) {
                    board[x][t] = board[x][y];
                }
                else if (board[x][t] == board[x][y]) {
                    // merge (increase power of two)
                    board[x][t]++;
                    // increase score
                    score += 1 << board[x][t];
                    // set stop to avoid double merge
                    stop = t + 1;
                }
                board[x][y] = 0;
                success = true;
            }
        }
    }
    return success;
}

void rotateBoard() {
    uint8_t i, j, n = SIZE;
    uint8_t tmp;
    for (i = 0; i < n / 2; i++) {
        for (j = i; j < n - i - 1; j++) {
            tmp = board[i][j];
            board[i][j] = board[j][n - i - 1];
            board[j][n - i - 1] = board[n - i - 1][n - j - 1];
            board[n - i - 1][n - j - 1] = board[n - j - 1][i];
            board[n - j - 1][i] = tmp;
        }
    }
}

bool moveUp() {
    bool success = false;
    uint8_t x;
    for (x = 0; x < SIZE; x++) {
        success |= slideArray(x);
    }
    return success;
}

bool moveLeft() {
    bool success;
    rotateBoard();
    success = moveUp();
    rotateBoard();
    rotateBoard();
    rotateBoard();
    return success;
}

bool moveDown() {
    bool success;
    rotateBoard();
    rotateBoard();
    success = moveUp();
    rotateBoard();
    rotateBoard();
    return success;
}

bool moveRight() {
    bool success;
    rotateBoard();
    rotateBoard();
    rotateBoard();
    success = moveUp();
    rotateBoard();
    return success;
}

bool findPairDown() {
    bool success = false;
    uint8_t x, y;
    for (x = 0; x < SIZE; x++) {
        for (y = 0; y < SIZE - 1; y++) {
            if (board[x][y] == board[x][y + 1]) {
                return true;
            }
        }
    }
    return success;
}

uint8_t countEmpty() {
    uint8_t x, y;
    uint8_t count = 0;
    for (x = 0; x < SIZE; x++) {
        for (y = 0; y < SIZE; y++) {
            if (board[x][y] == 0) {
                count++;
            }
        }
    }
    return count;
}

bool gameEnded() {
    bool ended = true;
    uint8_t x, y;
    for (x = 0; x < SIZE; x++) {
        for (y = 0; y < SIZE - 1; y++) {
            if (board[x][y] == 13) {
                return true;
            }
        }
    }
    if (countEmpty() > 0) {
        return false;
    }
    if (findPairDown()) {
        return false;
    }
    rotateBoard(board);
    if (findPairDown()) {
        ended = false;
    }
    rotateBoard();
    rotateBoard();
    rotateBoard();
    return ended;
}

int r_reg() {
#asm
    ld a, r
    ld l, a
    ld h, 0
#endasm
}

void addRandom() {
    static bool initialized = false;
    uint8_t x, y;
    uint8_t r, len = 0;
    uint8_t n, list[SIZE * SIZE][2];

    if (!initialized) {
        srand(r_reg());
        initialized = true;
    }

    for (x = 0; x < SIZE; x++) {
        for (y = 0; y < SIZE; y++) {
            if (board[x][y] == 0) {
                list[len][0] = x;
                list[len][1] = y;
                len++;
            }
        }
    }

    if (len > 0) {
        r = rand() % len;
        x = list[r][0];
        y = list[r][1];
        n = (rand() % 10) / 9 + 1;
        board[x][y] = n;
    }
}

void initBoard() {
    uint8_t x, y;
    for (x = 0; x < SIZE; x++) {
        for (y = 0; y < SIZE; y++) {
            board[x][y] = 0;
        }
    }

    addRandom();
    addRandom();
    drawBoard();
    score = 0;
}

int main(int argc, char * argv[]) {
    uint8_t board[SIZE][SIZE];
    char c;
    bool success;

    printf("\033[?25l\033[2J");
    drawBorder();

    initBoard();
    while (true) {
        c = fgetc_cons();
        success = false;
        switch (c) {
            case 'w':	// 'w' key
            case CTRL_E:
                success = moveUp();
                break;
            case 's':	// 's' key
            case CTRL_X:
                success = moveDown();
                break;
            case 'd':	// 'd' key
            case CTRL_D:
                success = moveRight();
                break;
            case 'a':	// 'a' key
            case CTRL_S:
                success = moveLeft();
                break;
            case ESC:  // VT-100 key codes
                c = fgetc_cons();
                if (c == 'O') {
                    c = fgetc_cons();
                }
                switch (c) {
                    case 'A':
                        success = moveUp();
                        break;
                    case 'B':
                        success = moveDown();
                        break;
                    case 'C':
                        success = moveRight();
                        break;
                    case 'D':
                        success = moveLeft();
                        break;
                    default:
                        printf("\007");
                        break;
                }
                break;
            case 'q':
            case 'r':
                break;
            default:
                printf("\007");
                break;
        }
        drawBoard();
        if (success) {
            addRandom();
            drawBoard();
            if (gameEnded()) {
                printf("         GAME OVER          \n");
                break;
            }
        }
        if (c == 'q') {
            printf("        QUIT? (y/n)         \n");
            c = fgetc_cons();
            if (c == 'y') {
                break;
            }
            drawBoard();
        }
        if (c == 'r') {
            printf("       RESTART? (y/n)       \n");
            c = fgetc_cons();
            if (c == 'y') {
                initBoard();
            }
            drawBoard();
        }
    }

    printf("\033[?25h\033[m");

    return EXIT_SUCCESS;
}

