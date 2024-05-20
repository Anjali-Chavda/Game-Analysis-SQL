CREATE DATABASE GAME_ANALYSIS;
/*created database named Game_Analysis and added both table file to it*/

USE GAME_ANALYSIS;
/*using database to solve below given problem statement*/

/*PROBLEM 1 - Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0*/

SELECT pd.P_ID, ld.Dev_ID, pd.PName, ld.Difficulty
FROM player_details pd 
INNER JOIN level_details2 ld ON pd.P_ID = ld.P_ID
WHERE ld.Level = 0;

/*PROBLEM 2 - Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3 
stages are crossed*/

SELECT pd.L1_status, AVG(ld.Kill_Count) AS avg_kills
FROM player_details pd 
INNER JOIN level_details2 ld ON pd.P_ID = ld.P_ID
WHERE ld.Lives_earned = 2 AND ld.Stages_crossed >= 3
group by pd.L1_Status;

/*PROBLEM 3 - Find the total number of stages crossed at each difficulty level for Level 2 with players 
using `zm_series` devices. Arrange the result in decreasing order of the total number of 
stages crossed*/

SELECT ld.Difficulty, SUM(ld.Stages_Crossed) AS 'Total Stages Crossed' 
FROM level_details2 ld 
LEFT JOIN player_details pd ON ld.P_ID = pd.P_ID 
WHERE ld.Dev_ID LIKE 'zm%' AND ld.Level = 2 
GROUP BY ld.Difficulty 
ORDER BY 'Total Stages Crossed' DESC; 

/*PROBLEM 4 - Extract `P_ID` and the total number of unique dates for those players who have played 
games on multiple days*/

SELECT P_ID, COUNT(DISTINCT(Timestamp)) AS Unique_Dates 
FROM level_details2 
GROUP BY P_ID 
HAVING COUNT(DISTINCT(timestamp)) > 1;

/*PROBLEM 5 - Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the 
average kill count for Medium difficulty*/

SELECT P_ID, Level, SUM(kill_count) 
FROM level_details2 
WHERE kill_count > (SELECT AVG(kill_count) 
	FROM level_details2 
	WHERE Difficulty = 'Medium') 
GROUP BY Level, P_ID;

/*PROBLEM 6 - Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level 
0. Arrange in ascending order of level*/

SELECT ld.Level, pd.L1_Code, pd.L2_Code, SUM(ld.Lives_Earned) AS 'Total Lives Earned' 
FROM level_details2 ld 
JOIN player_details pd ON ld.P_ID = pd.P_ID 
WHERE ld.Level != 0 
GROUP BY ld.Level, pd.L1_Code, pd.L2_Code 
ORDER BY ld.Level;

/*PROBLEM 7 - Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using 
`Row_Number`. Display the difficulty as well.*/

SELECT * FROM (SELECT Score, Dev_ID, Difficulty, 
			   ROW_NUMBER () OVER(PARTITION BY Dev_ID ORDER BY Score DESC) AS position
			   FROM level_details2) my_table
WHERE position < 4;

/*PROBLEM 8 - Find the `first_login` datetime for each device ID*/

SELECT Dev_ID, MIN(Timestamp) AS 'first_login'
FROM level_details2 
GROUP BY Dev_ID;

/*PROBLEM 9 - Find the top 5 scores based on each difficulty level and rank them in increasing order 
using `Rank`. Display `Dev_ID` as well*/

SELECT * FROM (SELECT Score, Dev_ID, Difficulty, 
			   RANK () OVER(PARTITION BY Difficulty ORDER BY Score DESC) AS position 
			   FROM level_details2) my_table
WHERE position < 6;

/*PROBLEM 10 -  Find the device ID that is first logged in (based on `start_datetime`) for each player 
(`P_ID`). Output should contain player ID, device ID, and first login datetime*/

SELECT P_ID, Dev_ID, MIN(Timestamp) AS 'first_login'
FROM level_details2 
GROUP BY Dev_ID, P_ID;

/*PROBLEM 11 - For each player and date, determine how many `kill_counts` were played by the player 
so far*/
/*PROBLEM 11(A) - Using window functions*/

SELECT P_ID, CAST(Timestamp AS date) AS date_till, SUM(kill_count) AS kill_count, 
	   RANK() OVER(PARTITION BY P_ID ORDER BY CAST(Timestamp AS date)) AS raw_num
FROM level_details2
GROUP BY P_ID, CAST(Timestamp AS date)

/*PROBLEM 11(B) - Without window functions*/

SELECT P_ID, CAST(Timestamp AS date) AS date_till, SUM(kill_count) AS kill_counts 
FROM level_details2
GROUP BY P_ID, CAST(Timestamp AS date) 
ORDER BY P_ID;

/*PROBLEM 12 -  Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`, 
excluding the most recent `start_datetime`*/

SELECT *, SUM(sum_1) OVER (PARTITION BY P_ID ORDER BY Timestamp) AS cum_sum
FROM (SELECT P_ID, TimeStamp, SUM(Stages_crossed) AS sum_1, 
      RANK () OVER(PARTITION BY P_ID ORDER BY Timestamp DESC) AS position
FROM level_details2 
GROUP BY P_ID, Timestamp) mytable
WHERE position != 1;

/*PROBLEM 13 -  Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`*/

SELECT * FROM (SELECT *, 
               RANK () OVER(PARTITION BY Dev_ID ORDER BY total_score DESC) AS position
			   FROM (SELECT Dev_ID, P_ID, SUM(Score) AS total_score 
			         FROM level_details2 
					 GROUP BY Dev_ID, P_ID) my_table1) my_table11 
WHERE position < 4;

/*PROBLEM 14 - Find players who scored more than 50% of the average score, scored by the sum of 
scores for each `P_ID`*/

SELECT P_ID, SUM(Score) AS score2 
FROM level_details2 
GROUP BY P_ID 
HAVING SUM(Score) > (SELECT AVG(total_score)*1.5 AS benchmark 
					FROM (SELECT P_ID, SUM(Score) AS total_score 
					      FROM level_details2 
						  GROUP BY P_ID) my_table3)

/*PROBLEM 15 -  Create a stored procedure to find the top `n` `headshots_count` based on each `Dev_ID` 
and rank them in increasing order using `Row_Number`. Display the difficulty as well*/

CREATE PROCEDURE top_n3(@num_n AS INT)
AS
BEGIN
SELECT * FROM (SELECT Dev_ID, Difficulty, headshots_count, 
               RANK () OVER(PARTITION BY Dev_ID ORDER BY headshots_count DESC) AS eligible_rank
               FROM level_details2 
               GROUP BY Dev_ID, Difficulty, headshots_count) my_table
WHERE eligible_rank < @num_n 
ORDER BY Dev_ID, Headshots_Count ASC;
END;
GO

EXEC top_n3 @num_n = 4;