import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { randomUUID } from 'crypto';

const s3 = new S3Client({});

export const handler = async (event) => {
    console.log("Evento recibido:", JSON.stringify(event)); // Esto generará logs sí o sí
    try {
        const bucket = process.env.S3_BUCKET;
        const prefix = process.env.UPLOAD_PREFIX;
        
        const contentType = event.headers['content-type'] || event.headers['Content-Type'] || 'image/png';
        const fileName = `${randomUUID()}.png`;

        const fileBuffer = event.isBase64Encoded 
            ? Buffer.from(event.body, 'base64') 
            : Buffer.from(event.body);

        if (!fileBuffer || fileBuffer.length === 0) {
            throw new Error("El cuerpo de la imagen está vacío");
        }

        await s3.send(new PutObjectCommand({
            Bucket: bucket,
            Key: `${prefix}${fileName}`,
            Body: fileBuffer,
            ContentType: contentType
        }));

        return {
            statusCode: 201,
            body: JSON.stringify({ message: "Imagen recibida", file: fileName })
        };
    } catch (err) {
        console.error("ERROR CRITICO:", err.message);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: err.message, stack: err.stack })
        };
    }
};