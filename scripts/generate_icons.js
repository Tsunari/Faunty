const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const svgPath = path.join(__dirname, '../assets/logo.svg');
const svgSource = fs.readFileSync(svgPath, 'utf8');

const monogramSvgPath = path.join(__dirname, '../assets/logo_monogram.svg');
let monogramSvgSource = '';
if (fs.existsSync(monogramSvgPath)) {
  monogramSvgSource = fs.readFileSync(monogramSvgPath, 'utf8');
}

async function main() {
  console.log('Generating icon assets from vector mosque logo.svg...');

  // 1. Logo.png - Transparent, light theme version (uses high-contrast mosqueGradLight and removes background rect)
  const logoLightSvg = svgSource
    .replace(/<rect id="bgCard"[^>]*\/>/, '')
    .replace(/url\(#mosqueGrad\)/g, 'url(#mosqueGradLight)');
  
  await sharp(Buffer.from(logoLightSvg))
    .resize(512, 512)
    .png()
    .toFile(path.join(__dirname, '../assets/Logo_vector.png'));
  console.log('✔ Generated assets/Logo_vector.png (light theme UI, transparent bg alternative)');

  // 2. LogoInverse.png - Transparent, dark theme version (uses vibrant mosqueGrad and removes background rect)
  const logoDarkSvg = svgSource
    .replace(/<rect id="bgCard"[^>]*\/>/, '');

  await sharp(Buffer.from(logoDarkSvg))
    .resize(512, 512)
    .png()
    .toFile(path.join(__dirname, '../assets/LogoInverse_vector.png'));
  console.log('✔ Generated assets/LogoInverse_vector.png (dark theme UI, transparent bg alternative)');

  // Ensure web/icons directory exists
  const webIconsDir = path.join(__dirname, '../web/icons');
  if (!fs.existsSync(webIconsDir)) {
    fs.mkdirSync(webIconsDir, { recursive: true });
  }

  // 3. Web PWA Icons - Keep dark squircle background and vibrant mosqueGrad intact
  const sizes = [192, 512];
  for (const size of sizes) {
    const buffer = await sharp(Buffer.from(svgSource))
      .resize(size, size)
      .png()
      .toBuffer();

    fs.writeFileSync(path.join(webIconsDir, `Icon-%d.png`.replace('%d', size)), buffer);
    fs.writeFileSync(path.join(webIconsDir, `icon-%d.png`.replace('%d', size)), buffer);
    console.log(`✔ Generated web/icons/Icon-${size}.png (and lowercase)`);
  }

  // 4. Apple Touch Icon (180x180 with squircle background)
  await sharp(Buffer.from(svgSource))
    .resize(180, 180)
    .png()
    .toFile(path.join(webIconsDir, 'apple-touch-icon.png'));
  console.log('✔ Generated web/icons/apple-touch-icon.png');

  // 5. PWA Maskable Icons (Must scale down the entire content to 75% to fit inside safe zone)
  for (const size of [192, 512]) {
    const logoResized = await sharp(Buffer.from(svgSource))
      .resize(Math.round(size * 0.75), Math.round(size * 0.75))
      .png()
      .toBuffer();

    // Composite on top of solid background color of the squircle to cover padding
    await sharp({
      create: {
        width: size,
        height: size,
        channels: 4,
        background: '#010d0a' // Darkest color of the background gradient
      }
    })
      .composite([{ input: logoResized, gravity: 'center' }])
      .png()
      .toFile(path.join(webIconsDir, `icon-${size}-maskable.png`));
    console.log(`✔ Generated web/icons/icon-${size}-maskable.png`);
  }

  // 6. Favicon (32x32)
  await sharp(Buffer.from(svgSource))
    .resize(32, 32)
    .png()
    .toFile(path.join(webIconsDir, 'favicon.ico'));
  console.log('✔ Generated web/icons/favicon.ico');

  // 7. Compile Monogram Alternative Assets if monogram SVG is present
  if (monogramSvgSource) {
    console.log('Generating alternative monogram icon assets...');
    
    const monogramLightSvg = monogramSvgSource
      .replace(/<rect id="bgCard"[^>]*\/>/, '')
      .replace('fill="url(#textGrad)"', 'fill="url(#textGradLight)"');
    
    await sharp(Buffer.from(monogramLightSvg))
      .resize(512, 512)
      .png()
      .toFile(path.join(__dirname, '../assets/Logo_monogram.png'));
    console.log('✔ Generated assets/Logo_monogram.png');

    const monogramDarkSvg = monogramSvgSource
      .replace(/<rect id="bgCard"[^>]*\/>/, '');
    
    await sharp(Buffer.from(monogramDarkSvg))
      .resize(512, 512)
      .png()
      .toFile(path.join(__dirname, '../assets/LogoInverse_monogram.png'));
    console.log('✔ Generated assets/LogoInverse_monogram.png');
  }

  console.log('All icons generated successfully!');
}

main().catch(err => {
  console.error('Error generating icons:', err);
  process.exit(1);
});
