# Phantom

A pure Bash steganography tool that can hide and extract secret messages in both text and binary files. This tool uses LSB (Least Significant Bit) encoding for binary files and whitespace manipulation for text files.

## Features

- **Universal File Support**
  - Text files: Uses whitespace steganography
  - Binary files (images, etc.): Uses LSB steganography
  - Automatic file type detection
  
- **Security**
  - Optional AES-256-CBC encryption
  - PBKDF2 key derivation
  - Password-protected messages

- **Compatibility**
  - Pure Bash implementation
  - Minimal dependencies
  - Works on any Unix-like system

## Requirements

- Bash
- xxd
- OpenSSL
- file (for MIME type detection)
- Basic Unix utilities (dd, perl)

## Installation

1. Clone the script:
```bash
git clone https://github.com/moutaouakkil/Phantom.git
cd Phantom
```

2. Make it executable:
```bash
chmod +x phantom.sh
```

## Usage

### Basic Usage

1. Hide a message in a file:
```bash
./phantom.sh encode <file> "secret message"
```

2. Extract a hidden message:
```bash
./phantom.sh decode <file>
```

### Using Encryption

1. Hide an encrypted message:
```bash
./phantom.sh encode <file> "secret message" "your-password"
```

2. Extract and decrypt a message:
```bash
./phantom.sh decode <file> "your-password"
```

### Examples

1. Hide a message in a text file:
```bash
# Create a text file with enough lines
for i in {1..100}; do echo "Line $i" >> cover.txt; done

# Hide the message
./phantom.sh encode cover.txt "This is a secret message" "password123"

# Extract the message
./phantom.sh decode cover.txt "password123"
```

2. Hide a message in an image:
```bash
# Hide message in an image
./phantom.sh encode image.jpg "Hidden message in image" "password456"

# Extract the message
./phantom.sh decode image.jpg "password456"
```

## How It Works

### Text File Steganography
- Uses trailing whitespace to encode binary data
- Space represents '1', tab represents '0'
- Each character of the message requires 8 bits (one line per bit)

### Binary File Steganography
- Uses LSB (Least Significant Bit) encoding
- Modifies the least significant bit of each byte after file headers
- Preserves file structure and headers
- Includes message length in the encoding

### Encryption
- Uses OpenSSL's AES-256-CBC encryption
- PBKDF2 key derivation for enhanced security
- Base64 encoding for binary data handling

## Limitations

1. Text Files:
   - Requires enough lines to store the message (8 lines per character)
   - Visible trailing whitespace in some text editors
   - May be affected by text editors that automatically trim whitespace

2. Binary Files:
   - Small chance of visible artifacts in images
   - Limited message size based on file size
   - Some file formats may be more sensitive to LSB modification

## Security Considerations

1. This tool provides:
   - Message hiding through steganography
   - Optional AES-256 encryption
   - Password-based protection

2. However, be aware that:
   - File modification timestamps will change
   - Some file formats may compress or modify data
   - Strong passwords are essential for security

## Troubleshooting

1. "File needs more lines" error:
   - Add more lines to your text file (8 lines per character)

2. "Decryption failed" error:
   - Verify the correct password is being used
   - Ensure the file hasn't been modified since encoding

3. File corruption:
   - For binary files, ensure the file format supports LSB modification
   - Some formats (like JPEG) may compress and destroy hidden data

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

Developed by Othmane Moutaouakkil - Feel free to contact for issues or suggestions.
