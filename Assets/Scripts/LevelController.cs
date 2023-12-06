using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class LevelController : MonoBehaviour
{
    [SerializeField]
    private List<GameObject> balls;

    [SerializeField]
    private float gameSpeed = 1.0f;

    [SerializeField]
    private int currentLevel = 1;

    public List<GameObject> getBallsList()
    {
        return balls;
    }

    public float GetGameSpeed()
    {
        return gameSpeed;
    }

    public int GetLevel()
    {
        return currentLevel;
    }

    public void SetLevel(int level)
    {
       currentLevel = level;
    }

    public void LoadWinScene()
    {
        if (currentLevel + 4 == SceneManager.sceneCountInBuildSettings) //No more levels. Game is finished.
        {
            SceneManager.LoadScene(SceneManager.sceneCountInBuildSettings - 1); //Load last scene (Game finish scene)
        }
        else //Set the next level after the win screen.
        {
            PlayerPrefs.SetInt(Utils.LEVEL_SAVE_KEY, currentLevel + 1);
            SceneManager.LoadScene(1);
        }
    }

    public void LoadLoseScene()
    {
        SceneManager.LoadScene(2);
    }
}
