using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ScoreSystem : MonoBehaviour
{
    private int currentScore;
    private int ballCount;
    private LevelController levelController;
    private GameUI gameUI;

    // Start is called before the first frame update
    void Start()
    {
        currentScore = 0;
        ballCount = FindObjectOfType<LevelController>().getBallsList().Count;
        levelController = FindObjectOfType<LevelController>();
        gameUI = FindObjectOfType<GameUI>();
    }

    public void UpdateScore()
    {
        int remainingBalls = levelController.getBallsList().Count;
        int scoredBalls = ballCount - remainingBalls;
        currentScore = (int)(((double)scoredBalls / ballCount) * 100.0);
        gameUI.UpdateGameUI(currentScore);
    }

    public int GetScore()
    {
        return currentScore;
    }
}
