import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// ---------------------------------------------------------
// PATH 1: addDogProfile (สำหรับเพิ่มข้อมูล)
// ---------------------------------------------------------
export const addDogProfile = functions.https.onRequest(
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");

    if (req.method !== "POST") {
      res.status(405).send("กรุณาส่งแบบ POST");
      return;
    }

    try {
      const {dogName, breed, age} = req.body;

      if (!dogName) {
        res.status(400).json({success: false, message: "Missing dogName"});
        return;
      }

      const result = await db.collection("dogs").add({
        dogName,
        breed: breed || "ไม่ระบุ",
        age: age || 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      res.status(201).json({success: true, id: result.id});
    } catch (error) {
      res.status(500).json({success: false, error: String(error)});
    }
  }
);

// ---------------------------------------------------------
// PATH 2: getDogList (สำหรับดึงข้อมูล)
// ---------------------------------------------------------
export const getDogList = functions.https.onRequest(
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");

    try {
      const snapshot = await db.collection("dogs").get();
      const dogs = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      res.status(200).json(dogs);
    } catch (error) {
      res.status(500).json({success: false, error: String(error)});
    }
  }
);
// ปล่อยบรรทัดนี้ว่างไว้ 1 บรรทัด (ESLint บังคับให้มี Newline ท้ายไฟล์)
