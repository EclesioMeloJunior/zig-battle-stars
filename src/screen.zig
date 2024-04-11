const raylib = @cImport({
    @cInclude("raylib.h");
});

pub const SCREEN_WIDTH: c_int = 800;
pub const SCREEN_HEIGHT: c_int = 450;

pub fn collision_happened(object_A: raylib.Rectangle, object_B: raylib.Rectangle) bool {
    return object_B.x + object_B.width >= object_A.x and
        object_B.x <= object_A.x + object_A.width and
        object_B.y + object_B.height >= object_A.y and
        object_B.y <= object_A.y + object_A.height;
}
