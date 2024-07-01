#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>

// Define image type
typedef struct
{
    int width;
    int height;
    uint32_t *pixels;
} image_t;

// Define pixel type for
typedef struct
{
    uint8_t red;
    uint8_t green;
    uint8_t blue;
} pixel_t;

typedef struct
{
    uint32_t row;
    uint32_t col;
    pixel_t color;
} point_t;

// Define function prototypes
bool LoadImage(image_t *image, const char *filename);
pixel_t GetPixel(image_t *image, int x, int y);
point_t GetPoint(image_t *image, int row, int col);
int GetShape(image_t *image);
int CheckBottomRight(image_t *image, point_t *point, int row, int col);
int CheckShape(image_t *image, point_t *point);
int CheckSquare(image_t *image, point_t *point, point_t *secondPoint);
int CheckLine(image_t *image, point_t *point, point_t *secondPoint);
int BlackPixel(point_t *point);

// Initialize global variables
image_t frame;
point_t *points;
FILE *file;

int found = 0;

char filename[100] = "input.bmp";

int main()
{
    file = fopen("output.txt", "wb");

    image_t image;

    if (!LoadImage(&image, filename))
    {
        printf("Error: Could not load image %s\n", filename);
        return 1;
    }

    printf("image loaded: %d x %d\n", image.width, image.height);

    GetShape(&image);

    return 0;
}

point_t GetPoint(image_t *image, int row, int col)
{
    point_t point = points[row * image->width + col];

    return point;
}

int GetShape(image_t *image)
{
    FILE *output = fopen("output.txt", "wb");

    points = malloc(image->width * image->height * sizeof(point_t));
    int pointCount = 0;

    for (int i = 0; i < image->height; i++)
    {
        for (int j = 0; j < image->width; j++)
        {
            pixel_t pixel = GetPixel(image, j, i);

            point_t point;
            point.row = i;
            point.col = j;
            point.color = pixel;

            points[pointCount] = point;
            pointCount++;
        }
    }

    for (int i = 0; i < pointCount; i++)
    {
        // Check if pixel is black
        if (!BlackPixel(&points[i]))
        {
            continue;
        }

        // Check if bottom right pixel is black (to avoid 2..n counting)
        if (!CheckBottomRight(image, &points[i], points[i].row, points[i].col))
        {
            continue;
        }

        // Check if shape is valid
        if (!CheckShape(image, &points[i]))
        {

            continue;
        }

        found += 1;

        int x = points[i].col;
        int y = image->height - points[i].row - 1;

        if (found > 50)
        {
            break;
        }

        printf("%d: [%d %d] %d %d %d\n", found, x, y, points[i].color.red, points[i].color.green, points[i].color.blue);
        fprintf(output, "%d: [%d %d] %d %d %d\n", found, x, y, points[i].color.red, points[i].color.green, points[i].color.blue);
    }

    fclose(output);

    return 1;
}

// Check if square between two points is all black
int CheckSquare(image_t *image, point_t *point, point_t *secondPoint)
{
    // int firstX;
    // int secondX;

    // if (point->col > secondPoint->col)
    // {
    //     firstX = secondPoint->col;
    //     secondX = point->col;
    // }
    // else
    // {
    //     firstX = point->col;
    //     secondX = secondPoint->col;
    // }

    // int firstY;
    // int secondY;

    int firstX = point->col;
    int secondX = secondPoint->col;
    int firstY = point->row;
    int secondY = secondPoint->row;

    if (point->row > secondPoint->row)
    {
        firstY = secondPoint->row;
        secondY = point->row;
    }
    else
    {
        firstY = point->row;
        secondY = secondPoint->row;
    }

    for (int i = firstX; i <= secondX; i++)
    {
        for (int j = firstY; j <= secondY; j++)
        {
            point_t current = GetPoint(image, j, i);

            if (!BlackPixel(&current))
            {
                return 0;
            }
        }
    }

    return 1;
}

// Check if all pixels between two points are black
int CheckLine(image_t *image, point_t *point, point_t *secondPoint)
{
    int firstX;
    int secondX;

    if (point->col > secondPoint->col)
    {
        firstX = secondPoint->col;
        secondX = point->col;
    }
    else
    {
        firstX = point->col;
        secondX = secondPoint->col;
    }

    int firstY;
    int secondY;

    if (point->row > secondPoint->row)
    {
        firstY = secondPoint->row;
        secondY = point->row;
    }
    else
    {
        firstY = point->row;
        secondY = secondPoint->row;
    }

    if (firstX == secondX)
    {
        for (int i = firstY; i <= secondY; i++)
        {
            point_t current = GetPoint(image, i, firstX);

            if (BlackPixel(&current))
            {
                return 0;
            }
        }
    }
    else if (firstY == secondY)
    {
        for (int i = firstX; i <= secondX; i++)
        {
            point_t current = GetPoint(image, firstY, i);

            if (BlackPixel(&current))
            {
                return 0;
            }
        }
    }

    return 1;
}

// Check shape
int CheckShape(image_t *image, point_t *point)
{
    int row = point->row;
    int col = point->col;

    int shapeHeight = 0;
    int shapeHeightLineWidth = 0;
    int shapeWidth = 0;
    int shapeWidthLineWidth = 0;

    // Check how long black pixels keep showing up after increasing row
    for (int i = row; i < image->height; i++)
    {
        point_t current = GetPoint(image, i, col);

        if (BlackPixel(&current))
        {
            shapeHeight++;
        }
        else
        {

            // Check how long black pixels keep showing up after increasing col to find line width
            for (int j = col; j > 0; j--)
            {
                // Minus one since we reached a non-black pixel and we want the last black
                int currentRow = i - 1;

                point_t current = GetPoint(image, currentRow, j);

                if (BlackPixel(&current))
                {
                    shapeHeightLineWidth++;
                }
                else
                {
                    break;
                }
            }

            break;
        }
    }

    // Check how long black pixels keep showing up after increasing col
    for (int i = col; i > 0; i--)
    {
        point_t current = GetPoint(image, row, i);

        if (BlackPixel(&current))
        {
            shapeWidth++;
        }
        else
        {
            // Check how long black pixels keep showing up after increasing col to find line width
            for (int j = row; j < image->height; j++)
            {
                // Minus one since we reached a non-black pixel and we want the last black
                int currentCol = i + 1;

                point_t current = GetPoint(image, j, currentCol);

                if (BlackPixel(&current))
                {
                    shapeWidthLineWidth++;
                }
                else
                {
                    break;
                }
            }

            break;
        }
    }

    // Check if ratio is 1 / 2
    if (shapeHeight != shapeWidth * 2)
    {
        return 0;
    }

    // Check if line width are the same
    if (shapeHeightLineWidth != shapeWidthLineWidth)
    {
        return 0;
    }

    // Set X and Y of second point from base point to check vertical shape of marker
    int firstSquarePointX = col - shapeHeightLineWidth + 1;
    int firstSquarePointY = row + shapeHeight - 1;
    point_t firstSquareSecondPoint = GetPoint(image, firstSquarePointY, firstSquarePointX);

    // Set X and Y of second point from base point to check horizontal shape of marker
    int secondSquarePointX = col - shapeWidth + 1;
    int secondSquarePointY = row + shapeWidthLineWidth - 1;
    point_t secondSquareSecondPoint = GetPoint(image, secondSquarePointY, secondSquarePointX);

    // Check square of lines of reverse L shape
    if (
        !CheckSquare(image, &firstSquareSecondPoint, point) ||
        !CheckSquare(image, &secondSquareSecondPoint, point))
    {
        return 0;
    }

    // Bottom line points
    int bottomRightPointX = col + 1;
    int bottomRightPointY = row - 1;
    point_t bottomRightPoint = GetPoint(image, bottomRightPointY, bottomRightPointX);
    int bottomLeftPointX = col - shapeWidth;
    int bottomLeftPointY = row - 1;
    point_t bottomLeftPoint = GetPoint(image, bottomLeftPointY, bottomLeftPointX);

    // Right line points
    int topRightPointX = col + 1;
    int topRightPointY = row + shapeHeight;
    point_t topRightPoint = GetPoint(image, topRightPointY, topRightPointX);

    // Top line points
    int topLeftPointX = col - shapeHeightLineWidth;
    int topLeftPointY = row + shapeHeight;
    point_t topLeftPoint = GetPoint(image, topLeftPointY, topLeftPointX);

    // Top left of bottom line
    int topLeftLinePointX = col - shapeWidth;
    int topLeftLinePointY = row + shapeWidthLineWidth;
    point_t topLeftLinePoint = GetPoint(image, topLeftLinePointY, topLeftLinePointX);

    // Intersection point
    int intersectionPointX = col - shapeHeightLineWidth;
    int intersectionPointY = row + shapeWidthLineWidth;
    point_t intersectionPoint = GetPoint(image, intersectionPointY, intersectionPointX);

    // Check all surrounding lines of reverse L shape
    if (
        !CheckLine(image, &bottomRightPoint, &bottomLeftPoint) ||
        !CheckLine(image, &bottomRightPoint, &topRightPoint) ||
        !CheckLine(image, &topRightPoint, &topLeftPoint) ||
        !CheckLine(image, &topLeftLinePoint, &bottomLeftPoint) ||
        !CheckLine(image, &intersectionPoint, &topLeftLinePoint) ||
        !CheckLine(image, &intersectionPoint, &topLeftPoint))
    {
        return 0;
    }

    return 1;
}

// Returns 1 if bottom right pixel is not black
int CheckBottomRight(image_t *image, point_t *point, int row, int col)
{
    if (row == 0 && col + 1 >= image->width)
    {
        return 1;
    }

    if (row == 0)
    {
        point_t right = points[row * image->width + (col + 1)];

        if (BlackPixel(&right))
        {
            return 0;
        }

        return 1;
    }

    if (col + 1 >= image->width)
    {
        point_t bottom = points[(row - 1) * image->width + col];

        if (BlackPixel(&bottom))
        {
            return 0;
        }

        return 1;
    }

    point_t bottom = points[((row - 1) * image->width) + col];
    point_t bottomRight = points[((row - 1) * image->width) + (col + 1)];
    point_t right = points[(row * image->width) + (col + 1)];

    if (BlackPixel(&bottomRight) || BlackPixel(&bottom) || BlackPixel(&right))
    {
        return 0;
    }

    return 1;
}

// CHeck if color is black
int BlackPixel(point_t *point)
{
    if (point->color.red == 0 && point->color.green == 0 && point->color.blue == 0)
    {
        return 1;
    }

    return 0;
}

// Get pixel from image
pixel_t GetPixel(image_t *image, int x, int y)
{
    pixel_t pixel;

    int index = y * image->width + x;

    uint32_t color = image->pixels[index];

    // for (int i = 31; i >= 0; i--)
    // {
    //     printf("%d", (color >> i) & 1);
    // }
    // printf("\n");

    // Read from color which is uint24_t stored in uint32_t
    pixel.red = (color & 0x00FF0000) >> 16;
    pixel.green = (color & 0x0000FF00) >> 8;
    pixel.blue = (color & 0x000000FF);

    return pixel;
}

// Load image from file
bool LoadImage(image_t *image, const char *filename)
{
    // Open file in read-binary mode
    FILE *file = fopen(filename, "rb");

    // Check if file exists
    if (!file)
    {
        return false;
    }

    // Offset file pointer to width and height (from beginning)
    fseek(file, 18, SEEK_SET);

    // Set the width and height of the image from file pointer
    fread(&image->width, sizeof(uint32_t), 1, file);
    fread(&image->height, sizeof(uint32_t), 1, file);

    // Calculate row padding by getting the remainder of width divided by 4
    int padding = (4 - (image->width * sizeof(uint32_t)) % 4) % 4;

    printf("Padding: %d\n", padding);

    // Offset file pointer to pixel data (from beginning)
    fseek(file, 28, SEEK_CUR);

    // Read pixels
    image->pixels = malloc(image->width * image->height * sizeof(uint32_t));

    for (int i = 0; i < image->height; i++)
    {
        for (int j = 0; j < image->width; j++)
        {
            fread(&image->pixels[i * image->width + j], sizeof(uint8_t) * 3, 1, file);
        }
    }

    fclose(file);
    return true;
}
