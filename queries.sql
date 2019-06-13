-- Query 1 - Brooklyn players
-- List the first name and last name of every player
-- that played at any time for the Brooklyn Dodgers.

SELECT DISTINCT nameFirst AS 'First Name', nameLast AS 'Last Name' 
FROM master,appearances, teams
WHERE master.masterID=appearances.masterID AND teams.teamID=appearances.teamID 
	AND teams.yearID=appearances.yearID AND appearances.teamID='BRO' AND teams.name='Brooklyn Dodgers' AND G_all>0 
ORDER BY master.nameLast;

-- Query 2 - Error Prone Players
-- List the name of each player with more than
-- 100 errors in some season in their career.

SELECT master.nameFirst AS 'First Name', master.nameLast AS 'Last Name',fielding.yearID AS 'Year',fielding.E AS 'Errors' 
FROM master,fielding
WHERE master.masterID=fielding.masterID AND fielding.E>100;

-- Query 3 - Braves First Basemen
-- List the players who appeared at first base
-- in any season for a team with "Braves" in the name.

SELECT DISTINCT master.nameFirst AS 'First Name', master.nameLast AS 'Last Name'
FROM master,appearances,teams
WHERE teams.teamID=appearances.teamID AND master.masterID=appearances.masterID AND G_1B > 0 and teams.name LIKE '%Braves%'
ORDER BY master.nameLast;

-- Query 4 - Expos Pitchers
-- List the first name and last name of every player that 
-- has pitched for the team named the "Montreal Expos".

SELECT DISTINCT master.nameFirst AS 'First Name', master.nameLast AS 'Last Name'
FROM master, appearances, teams
WHERE teams.teamID=appearances.teamID AND master.masterID=appearances.masterID AND teams.name='Montreal Expos' AND appearances.G_p > 0
ORDER BY master.nameLast;

-- Query 5 - World Series Winners
-- List the name of each team that has won the world series
-- and number of world series that it has won.

SELECT DISTINCT teams.name AS 'Team Name', COUNT(teams.WSWin='Y') AS 'World Series Won'
FROM teams
WHERE teams.WSWin='Y'
GROUP BY 1
ORDER BY COUNT(*);

-- Query 6 - Winningest Teams
-- List the winning percentage over a team's entire history.

SELECT DISTINCT teams.name AS 'Team Name', ROUND(SUM(teams.W)/SUM(teams.W + teams.L),4) AS 'Win Percentage', SUM(teams.W) AS 'Total Wins', SUM(teams.L) AS 'Total Losses'
FROM teams
GROUP BY 1;

-- Query 7 - Utah players
-- List the first name, last name, first year played, last year played, 
-- and lifetime batting average (h/ab) of every player who was born in Utah.

SELECT DISTINCT ROUND(SUM(batting.H)/SUM(batting.AB), 3) AS 'Average', SUM(batting.H) AS 'Hits',
	SUM(batting.AB) AS 'At Bats', master.nameFirst AS 'First Name', master.nameLast AS 'Last Name'
FROM master, batting
WHERE master.masterID=batting.masterID AND master.birthstate='UT' AND batting.AB > 0
GROUP BY master.nameFirst, master.nameLast, master.debut, master.finalGame
ORDER BY master.nameLast;

-- Query 8 - Home run ranking
-- Rank players by the number of home runs they have hit in any season and 
-- list the top ten such rankings of players.

SELECT ranked.nameFirst AS 'First Name', ranked.nameLast AS 'Last Name', ranked._rank AS 'Rank', ranked.HR AS 'Home Runs'
FROM (SELECT master.nameFirst, master.nameLast, DENSE_RANK() OVER (ORDER BY batting.HR DESC) AS _rank, batting.HR
	FROM batting
	INNER JOIN master ON batting.masterID = master.masterID
	ORDER BY batting.HR DESC) ranked
WHERE _rank <= 10;

-- Query 9 - Yankee Run Kings
-- List the name, year, and number of home runs hit for each New York Yankee batter,
-- but only if they hit the most home runs for any player in that season.

SELECT yankees.nameFirst AS 'First Name', yankees.nameLast AS 'Last Name', yankees.yearID AS 'Year', yankees.HR AS 'Home Runs'
FROM
	(SELECT nameFirst, nameLast, HR, yearID, _rank, name
	FROM (
		SELECT master.nameFirst, master.nameLast, batting.HR, batting.yearID, DENSE_RANK() OVER (PARTITION BY batting.yearID ORDER BY batting.HR DESC) AS _rank, teams.name
		FROM master, batting, teams
		WHERE batting.masterID=master.masterID AND teams.teamID=batting.teamID AND teams.yearID=batting.yearID			
		ORDER BY batting.yearID, batting.HR DESC
		) homeruns
	WHERE _rank = 1
	ORDER BY yearID, _rank
    ) AS yankees
WHERE yankees.name='New York Yankees';

-- Query 10 - Brooklyn Dodgers Only
-- List the first name and last name of every player that has played 
-- only for the Brooklyn Dodgers

SELECT DISTINCT master.nameFirst AS 'First Name', master.nameLast AS 'Last Name'
FROM master, appearances, teams
WHERE master.masterID=appearances.masterID AND appearances.teamID=teams.teamID AND appearances.yearID=teams.yearID AND teams.name='Brooklyn Dodgers' AND 
appearances.masterID NOT IN
	(SELECT DISTINCT appearances.masterID
	FROM appearances, teams
	WHERE appearances.teamID=teams.teamID AND appearances.yearID=teams.yearID AND teams.name NOT IN ('Brooklyn Dodgers'))
ORDER BY master.nameLast;

-- Query 11 - Bumper Salary Teams
-- List the total salary for two consecutive years, team name, and year for 
-- every team that had a total salary which was 1.5 times as much as for the previous year.

SELECT allSalaries.name AS 'Team Name',allSalaries.lgID AS 'League',allSalaries.PreviousSalary,allSalaries.PreviousYear,
	allSalaries2.Salary,allSalaries2.Year,ROUND((salary/previousSalary)*100) AS 'Percent Increase'
FROM
	(SELECT DISTINCT teams.name, teams.lgID, SUM(salaries.salary) OVER(PARTITION BY teams.name,teams.yearID) AS 'PreviousSalary',
		salaries.yearID AS 'PreviousYear', DENSE_Rank() over (order by teams.name,teams.yearID) AS _rank
	FROM teams, salaries
	WHERE teams.teamID=salaries.teamID AND teams.yearID=salaries.yearID AND teams.lgID=salaries.lgID
	ORDER BY teams.name,teams.yearID
    ) allSalaries
    
INNER JOIN
    
    (SELECT DISTINCT teams.name, teams.lgID, SUM(salaries.salary) OVER(PARTITION BY teams.name,teams.yearID) AS 'Salary',
		salaries.yearID AS 'Year', DENSE_Rank() over (order by teams.name,teams.yearID) AS _rank2
	FROM teams, salaries
	WHERE teams.teamID=salaries.teamID AND teams.yearID=salaries.yearID AND teams.lgID=salaries.lgID
	ORDER BY teams.name,teams.yearID) allSalaries2

ON  _rank + 1 = _rank2
WHERE 1.5<=(Salary/PreviousSalary)
ORDER BY year;

-- Query 12 - Brooklyn Dodger Pitchers Three
-- List the first name and last name of every player that pitched for the 
-- Brooklyn Dodgers in at least three consecutive years.

SELECT DISTINCT nameFirst,nameLast
FROM teams,
	(SELECT DISTINCT master.nameFirst, master.nameLast, ap.yearID, ap.teamID, ap.lgID
	FROM master
	INNER JOIN (
		SELECT DISTINCT p1.masterID, p1.teamID, p1.yearID, p1.lgID
		FROM pitching AS p1
		JOIN pitching AS p2 ON p1.yearID = p2.yearID-1 AND p1.masterID = p2.masterID
		JOIN pitching AS p3 ON p1.yearID = p3.yearID-1 AND p1.masterID = p3.masterID
	) AS ap ON ap.masterID=master.masterID
) answer
WHERE teams.yearID=answer.yearID AND teams.lgID=answer.lgID AND teams.teamID=answer.teamID
AND teams.name='Brooklyn Dodgers'
ORDER BY nameLast;

-- Query 13 - Third best hits each year
-- List the first name, last name, year and number of hits
-- of every player that hit the third most number of hits for that year.

SELECT nameFirst AS 'First Name', nameLast AS 'Last Name', H AS 'Hits', yearID AS 'Years'
FROM (
	SELECT master.nameFirst, master.nameLast, batting.H, batting.yearID, DENSE_RANK() OVER (PARTITION BY batting.yearID ORDER BY batting.H DESC) AS thirdHighest
	FROM master,batting
	WHERE batting.masterID=master.masterID
	ORDER BY batting.yearID, batting.H DESC
    ) third
WHERE thirdHighest = 3
ORDER BY thirdHighest;

-- Query 14 - Two degrees from Yogi Berra
-- List the name of each player who appeared on a team with a player that 
-- was at one time was a teamate of Yogi Berra.

SELECT DISTINCT master.nameFirst, master.nameLast
FROM master, appearances, teams,
	(SELECT DISTINCT teams.name, teams.yearID
	FROM
		(SELECT DISTINCT teams.name, teams.yearID
		FROM master, appearances, teams
		WHERE appearances.masterID=master.masterID AND teams.teamID=appearances.teamID AND teams.yearID=appearances.yearID AND
			master.nameFirst='Yogi' AND master.nameLast='Berra'
		) firstDegree, master, appearances, teams
	WHERE appearances.masterID=master.masterID AND teams.teamID=appearances.teamID AND teams.yearID=appearances.yearID AND
		firstDegree.name=teams.name AND firstDegree.yearID=teams.yearID) secondDegree
        
WHERE appearances.masterID=master.masterID AND teams.teamID=appearances.teamID AND teams.yearID=appearances.yearID
	AND secondDegree.name IN (teams.name) AND secondDegree.yearID IN (teams.yearID);

-- Query 15 - Traveling with Rickey
-- List all of the teams for which Rickey Henderson did not play.

SELECT DISTINCT teams.name
FROM
	(SELECT DISTINCT YEAR(master.debut) AS debut, YEAR(master.finalGame) AS finalGame, master.masterID, teams.teamID, teams.name
	FROM appearances
	INNER JOIN master ON appearances.masterID = master.masterID AND master.nameFirst='Rickey' AND master.nameLast='Henderson' AND master.masterID='henderi01'
    	INNER JOIN teams ON teams.teamID=appearances.teamID and teams.yearID=appearances.yearID and appearances.masterID='henderi01') hender, teams, appearances, master
WHERE teams.yearID=appearances.yearID AND teams.teamID=appearances.teamID AND master.masterID=appearances.masterID
AND teams.yearID BETWEEN hender.debut AND hender.finalGame AND teams.name NOT IN (hender.name)
ORDER BY teams.name;

-- Query 16 - Median team wins
-- For the 1970s, list the team name for teams in the National League ("NL") that had
-- the median number of total wins in the decade (1970-1979 inclusive).

SELECT DISTINCT name AS 'Team Name', _rank as 'Rank'
FROM
	(SELECT DISTINCT name, SUM(W) AS wins, RANK() OVER (ORDER BY SUM(W) DESC) AS _rank,CEILING((SUM(1)/2))+1 AS median
	FROM teams
	WHERE yearID between 1970 AND 1979 AND lgID='NL'
	GROUP BY 1
	ORDER BY _rank ASC) answer
WHERE _rank = median
GROUP BY 1;
