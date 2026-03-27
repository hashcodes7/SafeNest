import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class FirstTimeScreen extends StatefulWidget {
  const FirstTimeScreen({super.key});

  @override
  State<FirstTimeScreen> createState() => _FirstTimeScreenState();
}

class _FirstTimeScreenState extends State<FirstTimeScreen> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> _saveNameAndProceed() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name', style: TextStyle(color: Colors.white))),
        );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFCBEFB2);
    const darkGreenColor = Color(0xFF6F9D52);
    const textColor = Color(0xFF335C2B);
    const brownColor = Color(0xFFA67C52);

    return Scaffold(
      backgroundColor: bgColor,
      // Prevents the keyboard from pushing the background blobs up awkwardly
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          // Background blobs
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundShapesPainter(),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Owl and Branch
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Optional fallback branches if owl image doesn't have them
                        Column(
                          children: [
                            Container(
                              height: 12,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: brownColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            Container(
                              height: 12,
                              width: 180,
                              decoration: BoxDecoration(
                                color: brownColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                        // Owl Image
                        Image.asset(
                          'assets/owl.png',
                          height: 150,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.error_outline, size: 100, color: brownColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Welcome Texts
                    Text(
                      'HEY',
                      style: GoogleFonts.montserrat(
                        fontSize: 42,
                        fontWeight: FontWeight.w300,
                        color: textColor,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'PLEASED TO MEET YOU',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: textColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Input Field Pill
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: darkGreenColor,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        cursorColor: Colors.white,
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveNameAndProceed(),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          hintText: 'Enter your name...',
                          hintStyle: TextStyle(color: Colors.white60, fontSize: 16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Decorative line and subtext
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 2, width: 40, color: const Color(0xFFC4B891)),
                        const SizedBox(width: 8),
                        Container(height: 2, width: 60, color: const Color(0xFFC4B891)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'LETS EMBARK ON A JOURNEY TO STORING YOUR\nDATA SAFELY.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textColor.withOpacity(0.6),
                        letterSpacing: 0.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 2, width: 80, color: const Color(0xFFC4B891)),
                        const SizedBox(width: 8),
                        Container(height: 2, width: 30, color: const Color(0xFFC4B891)),
                      ],
                    ),
                    
                    // Explicit submit button just in case user doesn't hit enter
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _saveNameAndProceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('Continue'),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Colors matching the design
    final lightLeaf = Paint()..color = const Color(0xFF90BA6B)..style = PaintingStyle.fill;
    final darkLeaf = Paint()..color = const Color(0xFF4C8D38)..style = PaintingStyle.fill;
    final moundLight = Paint()..color = const Color(0xFF86C15D)..style = PaintingStyle.fill;
    final moundDark = Paint()..color = const Color(0xFF5D9D36)..style = PaintingStyle.fill;

    // Small leaves (rough approximations)
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.15, size.height * 0.55), width: 30, height: 45), darkLeaf);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.85, size.height * 0.56), width: 25, height: 40), lightLeaf);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.92, size.height * 0.58), width: 15, height: 25), darkLeaf);

    // Bottom left huge blob
    final path1 = Path();
    path1.moveTo(-size.width * 0.1, size.height);
    path1.quadraticBezierTo(size.width * 0.3, size.height * 0.7, size.width * 0.6, size.height);
    path1.close();
    canvas.drawPath(path1, moundLight);
    
    // Bottom right huge blob
    final path2 = Path();
    path2.moveTo(size.width * 0.4, size.height);
    path2.quadraticBezierTo(size.width * 0.6, size.height * 0.65, size.width * 1.1, size.height * 0.8);
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, moundDark);
    
    // Bottom left leaf shape pointing right
    final path3 = Path();
    path3.moveTo(size.width * 0.1, size.height * 0.85);
    path3.quadraticBezierTo(size.width * 0.15, size.height * 0.7, size.width * 0.35, size.height * 0.75);
    path3.quadraticBezierTo(size.width * 0.2, size.height * 0.9, size.width * 0.1, size.height * 0.85);
    path3.close();
    canvas.drawPath(path3, darkLeaf);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
