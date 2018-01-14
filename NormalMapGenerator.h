

typedef struct {
    double x;
    double y;
    double z;
} Vector;

inline Vector makeVector(double x, double y, double z)
{
    Vector v;
    v.x = x;
    v.y = y;
    v.z = z;
    return v;
}

inline Vector normalize(Vector v)
{
    double vectorLength = sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
    Vector result;

    if (vectorLength == 0.0)
    {
        result.x = 0.0;
        result.y = 0.0;
        result.z = 0.0;
    }
    else
    {
        result.x = v.x / vectorLength;
        result.y = v.y / vectorLength;
        result.z = v.z / vectorLength;
    }
    return result;
}

inline Vector cross(Vector a, Vector b)
{
    return makeVector(a.y * b.z - a.z * b.y,
                      a.z * b.x - a.x * b.z,
                      a.x * b.y - a.y * b.x);
}



inline Color generateNormal(float* buffer, int x, int y, int width, int height, float bumpScale)
{
    Color returnColor;
    
    int lx = x - 1;// > 0 ? x - 1 : 0;
    int rx = x + 1;// < width ? x + 1 : width - 1;
    int by = y - 1;// > 0 ? y - 1 : 0;
    int ty = y + 1;// < height ? y + 1 : height - 1;
    
    double h00, h01, h02, h10, h12, h20, h21, h22;
    h00 = buffer[by * width + lx];
    h01 = buffer[by * width + x];
    h02 = buffer[by * width + rx];
    h10 = buffer[y * width + lx];
    h12 = buffer[y * width + rx];
    h20 = buffer[ty * width + lx];
    h21 = buffer[ty * width + x];
    h22 = buffer[ty * width + rx];

    double ds = -h00 +
               -h10 * 2.0f +
               -h20 +
                h02 +
                h12 * 2.0f +
                h22;

    double dt = -h00 +
               -h01 * 2.0f +
               -h02 +
                h20 +
                h21 * 2.0f +
                h22;
                
    /*int rx = x + 1;
    int ty = y + 1;
    double h11 = buffer[y * width + x];
    double h12 = buffer[y * width + rx];
    double h21 = buffer[ty * width + x];

    double ds = h12 - h11;
    double dt = h21 - h11;*/

    Vector normal = makeVector(-ds * bumpScale, -dt * bumpScale, 1.0);
    normal = normalize(normal);

    returnColor.r = ((normal.x + 1.0) * 0.5);
    returnColor.g = ((normal.y + 1.0) * 0.5);
    returnColor.b = ((normal.z + 1.0) * 0.5);
    returnColor.a = 1.0f;
    
    return returnColor;
}
