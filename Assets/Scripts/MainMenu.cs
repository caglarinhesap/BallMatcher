using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;

public class MainMenu : MonoBehaviour
{
    private int currentLevel;

    [SerializeField]
    private TextMeshProUGUI levelText;
    [SerializeField]
    private GameObject howToPlayPanel;

    private void Start()
    {
        currentLevel = PlayerPrefs.GetInt(Utils.LEVEL_SAVE_KEY, 1);
        levelText.text = "LEVEL " + currentLevel;
    }
    public void StartGame()
    {
        SceneManager.LoadScene(currentLevel + 2); // Level indexes are starting from 3. Mainmenu, winscreen and losescreen are the first three.
    }

    public void ExpandHowToPlay()
    {
        howToPlayPanel.SetActive(true);
    }

    public void CollapseHowToPlay()
    {
        howToPlayPanel.SetActive(false);
    }
}
