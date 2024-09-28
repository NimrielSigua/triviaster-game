<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

class User
{
    function EnterGameStudent($json)
    {
        include "connection.php";

        $json = json_decode($json, true);
        $fullname = $json['fullname'];
        $role = $json['role']; // Use the role passed from Dart

        // Check if the user already exists
        $checkSql = "SELECT * FROM user WHERE fullname = :fullname AND role = :role";
        $checkStmt = $conn->prepare($checkSql);
        $checkStmt->bindParam(":fullname", $fullname);
        $checkStmt->bindParam(":role", $role);
        $checkStmt->execute();

        if ($checkStmt->rowCount() > 0) {
            // User already exists
            $user = $checkStmt->fetch(PDO::FETCH_ASSOC);
            unset($conn);
            unset($checkStmt);
            return json_encode([
                'exists' => true,
                'user_id' => $user['user_id'],
                'fullname' => $user['fullname'],
                'role' => $user['role']
            ]);
        } else {
            // Insert the new user data
            $sql = "INSERT INTO user (fullname, role) VALUES (:fullname, :role)";
            $stmt = $conn->prepare($sql);
            $stmt->bindParam(":fullname", $fullname);
            $stmt->bindParam(":role", $role);
            $stmt->execute();

            // Fetch the inserted user details
            $user_id = $conn->lastInsertId();
            $sql = "SELECT * FROM user WHERE user_id = :user_id";
            $stmt = $conn->prepare($sql);
            $stmt->bindParam(":user_id", $user_id);
            $stmt->execute();
            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            unset($conn);
            unset($stmt);
            return json_encode([
                'exists' => false,
                'user_id' => $user['user_id'],
                'fullname' => $user['fullname'],
                'role' => $user['role']
            ]);
        }
    }


    function displayTrivia()
    {
        include 'connection.php';

        // Fetch all trivia questions
        $sql = "SELECT * FROM triviatbl";
        $stmt = $conn->prepare($sql);
        $stmt->execute();
        $returnValue = $stmt->fetchAll(PDO::FETCH_ASSOC); // Ensure this is an array
        unset($conn);
        unset($stmt);
        echo json_encode($returnValue); // Return as JSON array
    }

    function displayCorrectUser($json)
    {
        include 'connection.php';

        $json = json_decode($json, true);

        $sql = "SELECT user.fullname
                FROM answertbl
                INNER JOIN user ON answertbl.user_id = user.user_id
                INNER JOIN active_trivia ON answertbl.question_id = active_trivia.question_id
                INNER JOIN triviatbl ON active_trivia.trivia_id = triviatbl.trivia_id
                WHERE answertbl.answer = triviatbl.correct_answer
                  AND answertbl.question_id = :question_id";

        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":question_id", $json['question_id']);
        $stmt->execute();
        $returnValue = $stmt->fetchAll(PDO::FETCH_ASSOC); // Ensure this is an array
        unset($conn);
        unset($stmt);
        echo json_encode($returnValue); // Return as JSON array
    }


    function VerifyAdmin($json)
    {
        include "connection.php";

        $json = json_decode($json, true);

        // Check if the user is an admin
        $sql = "SELECT * FROM user WHERE fullname = :fullname AND role = :role";
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":fullname", $json['fullname']);
        $stmt->bindParam(":role", $json['role']);
        $stmt->execute();

        if ($stmt->rowCount() > 0) {
            // User is an admin
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            unset($conn);
            unset($stmt);
            return json_encode([
                'is_admin' => true,
                'user_id' => $user['user_id'],
                'fullname' => $user['fullname']
            ]);
        } else {
            unset($conn);
            unset($stmt);
            return json_encode(['is_admin' => false]);
        }
    }

    function startTrivia($json)
    {
        include "connection.php";

        $json = json_decode($json, true);

        // Save the trivia question ID to the database
        $sql = "INSERT INTO active_trivia (trivia_id, status) VALUES (:trivia_id, :status)";
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":trivia_id", $json['trivia_id']);
        $stmt->bindParam(":status", $json['status']);
        $stmt->execute();

        unset($conn);
        unset($stmt);

        return json_encode(['success' => true]);
    }

    function addWinners($json)
    {
        include "connection.php";

        $json = json_decode($json, true);

        // Save the trivia question ID to the database
        $sql = "INSERT INTO winners (user_id, question_id) VALUES (:user_id, :question_id)";
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $json['user_id']);
        $stmt->bindParam(":question_id", $json['question_id']);
        $stmt->execute();

        unset($conn);
        unset($stmt);

        return json_encode(['success' => true]);
    }
    function updateTriviaStatus($json)
{
    include "connection.php";

    $json = json_decode($json, true);

    // Correct SQL syntax with SET clause
    $sql = "UPDATE active_trivia SET status = :status WHERE question_id = :question_id";
    $stmt = $conn->prepare($sql);
    $stmt->bindParam(":status", $json['status']);
    $stmt->bindParam(":question_id", $json['question_id']); // Make sure to include question_id in your JSON data

    try {
        $stmt->execute();
        $response = ['success' => true];
    } catch (PDOException $e) {
        $response = ['success' => false, 'error' => $e->getMessage()];
    }

    unset($conn);
    unset($stmt);

    return json_encode($response);
}

    function getActiveTrivia()
    {
        include 'connection.php';

        // Get a random active trivia question
        $sql = "SELECT * ,
active_trivia.question_id
FROM triviatbl
JOIN active_trivia ON triviatbl.trivia_id = active_trivia.trivia_id
WHERE active_trivia.status = 'active'
ORDER BY active_trivia.question_id DESC;"; // Get a random active trivia question
        $stmt = $conn->prepare($sql);
        $stmt->execute();
        $data = $stmt->fetch(PDO::FETCH_ASSOC);

        unset($conn);
        unset($stmt);

        return json_encode($data);
    }

    function submitAnswer($json)
    {
        include "connection.php";

        $json = json_decode($json, true);

        // Check if the necessary fields are present in the JSON
        if (!isset($json['user_id']) || !isset($json['answer']) || !isset($json['trivia_id'])) {
            return json_encode(['success' => false, 'message' => 'Missing required fields']);
        }

        // Save the user's answer to the database
        $sql = "INSERT INTO answertbl (user_id, answer, question_id) VALUES (:user_id, :answer, :trivia_id)";
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $json['user_id']);
        $stmt->bindParam(":answer", $json['answer']);
        $stmt->bindParam(":trivia_id", $json['trivia_id']);
        $stmt->execute();

        unset($conn);
        unset($stmt);

        return json_encode(['success' => true]);
    }
}

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $operation = $_GET['operation'];
    $json = isset($_GET['json']) ? $_GET['json'] : '';
} else if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $operation = $_POST['operation'];
    $json = isset($_POST['json']) ? $_POST['json'] : '';
}

$user = new User();
switch ($operation) {
    case "EnterGameStudent":
        echo $user->EnterGameStudent($json);
        break;
    case "displayTrivia":
        echo $user->displayTrivia();
        break;
    case "VerifyAdmin":
        echo $user->VerifyAdmin($json);
        break;
    case "startTrivia":
        echo $user->startTrivia($json);
        break;
    case "getActiveTrivia":
        echo $user->getActiveTrivia();
        break;
    case "submitAnswer":
        echo $user->submitAnswer($json);
        break;
    case "displayCorrectUser":
        echo $user->displayCorrectUser($json);
        break;
    case "updateTriviaStatus":
        echo $user->updateTriviaStatus($json);
        break;
    case "addWinners":
        echo $user->updateTriviaStatus($json);
        break;
}
