using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class EndScreen : MonoBehaviour
{

    public void LoadLevel()
    {
        int level = PlayerPrefs.GetInt(Utils.LEVEL_SAVE_KEY, 1);
        SceneManager.LoadScene(level + 2);
    }

    public void StartFromLevel1()
    {
        PlayerPrefs.SetInt(Utils.LEVEL_SAVE_KEY, 1);
        SceneManager.LoadScene(3);
    }

    public void ReturnToMainMenu()
    {
        SceneManager.LoadScene(0);
    }
}
