using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class GameUI : MonoBehaviour
{
    [SerializeField]
    private TMP_Text scorePercentageText;

    [SerializeField]
    private Slider scoreSlider;

    [SerializeField]
    private TMP_Text gameSpeedText;

    [SerializeField]
    private TMP_Text levelText;

    private LevelController levelController;


    // Start is called before the first frame update
    void Start()
    {
        levelController = FindObjectOfType<LevelController>();
        scorePercentageText.text = "0%";
        scoreSlider.value = 0;
        gameSpeedText.text = "x" + levelController.GetGameSpeed();
        levelText.text = "LEVEL " + levelController.GetLevel();
    }

    public void UpdateGameUI(int scorePercentage)
    {
        scoreSlider.value = scorePercentage;
        scorePercentageText.text = scorePercentage + "%";
    }

    public void RestartLevel()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
    }

    public void ExitLevel()
    {
        SceneManager.LoadScene(0);
    }
}
